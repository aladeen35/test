#!/usr/bin/env python3
"""Synthesize the sound effects for "فول مارك" (Full Mark).

All sounds are generated from scratch (no samples). Output: 16-bit mono WAV,
22050 Hz, written next to this script.

    pip install numpy
    python3 generate_sounds.py
"""
import os
import wave

import numpy as np

SR = 22050
OUT = os.path.dirname(os.path.abspath(__file__))
rng = np.random.default_rng(1234)  # fixed seed -> reproducible output


# ---------------------------------------------------------------- helpers
def t_axis(dur):
    return np.arange(int(round(dur * SR))) / SR


def db(x):
    return 10 ** (x / 20)


def normalize(x, peak_db=-1.0):
    m = np.max(np.abs(x))
    return x if m == 0 else x * (db(peak_db) / m)


def fade(x, fin=0.003, fout=0.005):
    x = x.copy()
    a, b = int(fin * SR), int(fout * SR)
    if a:
        x[:a] *= np.linspace(0, 1, a) ** 2
    if b:
        x[-b:] *= np.linspace(1, 0, b) ** 2
    return x


def adsr(n, a=0.005, d=0.05, s=0.7, r=0.1):
    a, d, r = int(a * SR), int(d * SR), int(r * SR)
    sus = max(n - a - d - r, 0)
    env = np.concatenate([
        np.linspace(0, 1, a, endpoint=False),
        np.linspace(1, s, d, endpoint=False),
        np.full(sus, s),
        np.linspace(s, 0, r),
    ])
    return np.pad(env, (0, max(0, n - len(env))))[:n]


def exp_env(n, tau):
    return np.exp(-np.arange(n) / (tau * SR))


def mix_at(buf, x, start, gain=1.0):
    s = int(start)
    e = min(len(buf), s + len(x))
    if e > s:
        buf[s:e] += x[: e - s] * gain


def osc(freq, n, kind="sine", phase=0.0):
    """freq may be scalar or per-sample array (for sweeps). Band-limited-ish."""
    f = np.broadcast_to(np.asarray(freq, dtype=float), (n,))
    ph = 2 * np.pi * np.cumsum(f) / SR + phase
    if kind == "sine":
        return np.sin(ph)
    # additive band-limited square/saw (harmonics below Nyquist)
    out = np.zeros(n)
    fmax = float(np.max(f))
    k = 1
    while k * fmax < SR / 2 * 0.9 and k < 60:
        if kind == "saw":
            out += ((-1) ** (k + 1)) * np.sin(k * ph) / k
        elif kind == "square" and k % 2 == 1:
            out += np.sin(k * ph) / k
        k += 1
    return out * (2 / np.pi if kind == "saw" else 4 / np.pi)


def fft_filter(x, lo=None, hi=None, order=2):
    """Zero-phase smooth band filter in the frequency domain."""
    n = len(x)
    N = 1 << int(np.ceil(np.log2(n * 2)))
    X = np.fft.rfft(x, N)
    f = np.fft.rfftfreq(N, 1 / SR)
    H = np.ones_like(f)
    if hi:
        H *= 1 / np.sqrt(1 + (f / hi) ** (2 * order))
    if lo:
        with np.errstate(divide="ignore"):
            H *= 1 / np.sqrt(1 + (lo / np.maximum(f, 1e-6)) ** (2 * order))
    return np.fft.irfft(X * H, N)[:n]


def svf_bandpass(x, fc, q=2.0):
    """Time-varying state-variable band-pass (fc may be an array)."""
    fc = np.broadcast_to(np.asarray(fc, dtype=float), x.shape)
    low = band = 0.0
    out = np.empty_like(x)
    damp = 1.0 / q
    for i in range(len(x)):
        f = 2 * np.sin(np.pi * min(fc[i], SR / 6) / SR)
        high = x[i] - low - damp * band
        band += f * high
        low += f * band
        out[i] = band
    return out


def comb(x, delay_s, g):
    D = int(delay_s * SR)
    y = x.copy()
    for i in range(D, len(y), D):
        seg = y[i - D:i]
        y[i:i + len(seg)] += g * seg[: len(y) - i]
    return y


def reverb(x, wet=0.2, size=1.0, tail=0.6, damp_hz=5000):
    """Small Schroeder-style room: parallel combs + low-pass damping."""
    x = np.concatenate([x, np.zeros(int(tail * SR))])
    delays = [0.0297, 0.0371, 0.0411, 0.0437]
    w = sum(comb(x, d * size, 0.72) for d in delays) / len(delays)
    w = fft_filter(w, lo=150, hi=damp_hz)
    return x * (1 - wet) + w * wet * 2.0


def trim_silence(x, thresh_db=-60, keep=0.01):
    idx = np.where(np.abs(x) > db(thresh_db) * np.max(np.abs(x)))[0]
    if len(idx) == 0:
        return x
    return x[: min(len(x), idx[-1] + int(keep * SR))]


def bell(freq, dur, amp=1.0):
    n = int(dur * SR)
    t = np.arange(n) / SR
    # inharmonic-ish bell partials (ratio, gain, decay)
    partials = [(1.0, 1.0, 0.45), (2.0, 0.55, 0.30), (3.0, 0.25, 0.18),
                (4.2, 0.18, 0.12), (5.4, 0.10, 0.08), (2.76, 0.12, 0.2)]
    out = np.zeros(n)
    for r, g, d in partials:
        if freq * r < SR / 2 * 0.9:
            out += g * np.sin(2 * np.pi * freq * r * t) * np.exp(-t / d)
    atk = int(0.002 * SR)
    out[:atk] *= np.linspace(0, 1, atk)
    return out * amp


def brass(freq, dur, amp=1.0, vib=True):
    """Brass-like tone: saw harmonics with a brightness envelope that opens."""
    n = int(dur * SR)
    t = np.arange(n) / SR
    f = freq * (1 + (0.004 * np.sin(2 * np.pi * 5.5 * t) * np.clip(t / 0.25, 0, 1) if vib else 0))
    ph = 2 * np.pi * np.cumsum(f) / SR
    bright = np.clip(t / 0.06, 0, 1) * 0.7 + 0.3          # "blat" opening
    out = np.zeros(n)
    for k in range(1, 30):
        if k * freq > SR / 2 * 0.85:
            break
        # higher harmonics come in as brightness rises
        gk = (1 / k) * np.clip(bright * 12 / k, 0, 1)
        out += gk * np.sin(k * ph)
    env = adsr(n, a=0.025, d=0.08, s=0.8, r=min(0.12, dur * 0.4))
    return out * env * amp


def write(name, x, peak_db=-1.0):
    x = normalize(fade(x), peak_db)
    pcm = np.clip(np.round(x * 32767), -32768, 32767).astype("<i2")
    path = os.path.join(OUT, name)
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    return path


# ---------------------------------------------------------------- sounds
def make_tick():
    n = int(0.08 * SR)
    t = np.arange(n) / SR
    click = rng.standard_normal(n) * exp_env(n, 0.0025)
    click = fft_filter(click, lo=2500, hi=9000)
    body = np.sin(2 * np.pi * 1800 * t) * exp_env(n, 0.008) * 0.6 \
        + np.sin(2 * np.pi * 3400 * t) * exp_env(n, 0.004) * 0.3
    return click + body


def make_correct():
    out = np.zeros(int(0.7 * SR))
    mix_at(out, bell(1046.5, 0.7), 0)                 # C6
    mix_at(out, bell(1318.5, 0.7 - 0.12), 0.12 * SR)  # E6
    mix_at(out, bell(1568.0, 0.7 - 0.12) * 0.35, 0.12 * SR)  # G6 sparkle
    out = reverb(out, wet=0.18, size=0.8, tail=0.0)
    return out[: int(0.7 * SR)]


def make_wrong():
    n = int(0.6 * SR)
    t = np.arange(n) / SR
    f = 140 * (1 - 0.12 * t / 0.6)          # slight downward pitch
    x = 0.5 * osc(f, n, "square") + 0.5 * osc(f * 1.012, n, "saw") \
        + 0.35 * osc(f * 0.5, n, "square")
    x = fft_filter(x, hi=1800, order=2)     # tame harshness
    env = adsr(n, a=0.01, d=0.05, s=0.85, r=0.12)
    # gentle "eh-eh" flutter
    env *= 1 - 0.18 * (0.5 + 0.5 * np.sin(2 * np.pi * 11 * t))
    return x * env


def make_timeup():
    total = 0.8
    out = np.zeros(int(total * SR))
    seg = 0.2
    for i, f in enumerate([880, 660, 880, 660]):
        n = int(seg * SR)
        tone = 0.6 * osc(f, n, "square") + 0.4 * osc(f * 1.005, n, "saw")
        tone = fft_filter(tone, hi=3500)
        tone *= adsr(n, a=0.008, d=0.03, s=0.85, r=0.03)
        mix_at(out, tone, i * seg * SR)
    out = reverb(out, wet=0.15, size=0.7, tail=0.0)
    return out[: int(total * SR)] * adsr(len(out[: int(total * SR)]), 0.002, 0.01, 1, 0.06)


def snare_hit(n_len=0.12, tone_f=190, bright=1.0):
    n = int(n_len * SR)
    t = np.arange(n) / SR
    noise = fft_filter(rng.standard_normal(n), lo=1200, hi=7000 * bright) * exp_env(n, 0.035)
    body = np.sin(2 * np.pi * tone_f * t) * exp_env(n, 0.02) * 0.5
    return noise + body


def cymbal(dur=1.4):
    n = int(dur * SR)
    t = np.arange(n) / SR
    x = rng.standard_normal(n)
    # metallic: ring-modulated square partials + noise
    metal = sum(np.sign(np.sin(2 * np.pi * f * t)) for f in [587, 845, 1031, 1467, 1873, 2539])
    x = fft_filter(x * 0.7 + metal * 0.12, lo=3000, hi=10000)
    env = np.exp(-t / 0.45) * np.clip(t / 0.003, 0, 1)
    return x * env


def make_drumroll():
    total = 2.2
    out = np.zeros(int(total * SR))
    roll_end = 1.45
    tt = 0.0
    while tt < roll_end:
        p = tt / roll_end
        gap = 0.075 - 0.040 * p                       # roll speeds up
        vel = 0.25 + 0.75 * p ** 1.5                  # crescendo
        vel *= 0.85 + 0.3 * rng.random()
        mix_at(out, snare_hit(0.1, 180 + 30 * rng.random(), 0.8 + 0.3 * p) * vel, tt * SR)
        tt += gap
    # final accent + crash
    hit = roll_end + 0.04
    mix_at(out, snare_hit(0.2, 170) * 1.2, hit * SR)
    kick_n = int(0.3 * SR)
    kt = np.arange(kick_n) / SR
    kick = np.sin(2 * np.pi * np.cumsum(55 + 90 * np.exp(-kt / 0.03)) / SR) * exp_env(kick_n, 0.12)
    mix_at(out, kick * 1.3, hit * SR)
    mix_at(out, cymbal(total - hit) * 0.9, hit * SR)
    out = reverb(out, wet=0.18, size=1.1, tail=0.0)
    out = out[: int(total * SR)]
    return out * adsr(len(out), 0.002, 0.01, 1.0, 0.25)


def make_applause():
    total = 3.0
    n = int(total * SR)
    t = np.arange(n) / SR
    out = np.zeros(n)
    # swell -> sustain -> fade density/level envelope
    level = np.clip(t / 0.6, 0, 1) ** 1.5 * np.clip((total - t) / 1.4, 0, 1) ** 1.3
    n_claps = 2600
    clap_n = int(0.02 * SR)
    for _ in range(n_claps):
        st = rng.random() * total
        i = int(st * SR)
        if level[min(i, n - 1)] < rng.random() * 0.9:
            continue
        c = rng.standard_normal(clap_n) * exp_env(clap_n, 0.003 + 0.004 * rng.random())
        mix_at(out, c * (0.4 + 0.6 * rng.random()), i)
    # each "person" has a different hand resonance; split into 3 bands
    out = (fft_filter(out, lo=600, hi=2500) * 0.9 + fft_filter(out, lo=1500, hi=6000) * 0.6
           + fft_filter(out, lo=300, hi=900) * 0.3)
    # crowd bed + a few "woo" cheers
    bed = fft_filter(rng.standard_normal(n), lo=400, hi=3000) * 0.08 * level
    cheers = np.zeros(n)
    for _ in range(5):
        st = 0.3 + rng.random() * 1.6
        d = 0.5 + rng.random() * 0.5
        cn = int(d * SR)
        ct = np.arange(cn) / SR
        f0 = 550 + rng.random() * 350
        f = f0 * (1 + 0.25 * np.sin(np.pi * ct / d))  # "woo" up-down glide
        v = sum(np.sin(2 * np.pi * np.cumsum(f * k) / SR) / k ** 1.5 for k in range(1, 6))
        v *= np.sin(np.pi * ct / d) ** 2 * (1 + 0.1 * np.sin(2 * np.pi * 6 * ct))
        mix_at(cheers, v * 0.06, st * SR)
    cheers = fft_filter(cheers, lo=300, hi=3500)
    x = out * level + bed + cheers
    x = reverb(x, wet=0.25, size=1.2, tail=0.0)[:n]
    return x * adsr(n, 0.01, 0.01, 1.0, 0.4)


def make_fanfare():
    total = 2.2
    out = np.zeros(int(total * SR))
    # Bb major-ish triumphant call: G4 C5 E5 G5 ... C major ending
    C4, E4, G4, C5, E5, G5 = 261.63, 329.63, 392.0, 523.25, 659.25, 783.99
    notes = [  # (start, dur, freq, amp)
        (0.00, 0.14, G4, 0.8), (0.15, 0.14, G4, 0.8), (0.30, 0.14, G4, 0.8),
        (0.45, 0.30, C5, 1.0), (0.78, 0.14, E5, 0.9), (0.93, 0.14, G5, 0.9),
        (1.08, 0.18, E5, 0.85),
    ]
    for st, d, f, a in notes:
        mix_at(out, brass(f, d + 0.04, a), st * SR)
    # final sustained C major chord with timpani hit
    st, d = 1.28, total - 1.28
    for f, a in [(C4, 0.7), (E4, 0.6), (G4, 0.6), (C5, 0.8), (G5 / 2 * 2, 0.35)]:
        tone = brass(f, d, a)
        tone *= adsr(len(tone), 0.03, 0.1, 0.85, 0.45)
        mix_at(out, tone, st * SR)
    tn = int(0.6 * SR)
    tt = np.arange(tn) / SR
    timp = np.sin(2 * np.pi * np.cumsum(98 * (1 + 0.15 * np.exp(-tt / 0.03))) / SR) * exp_env(tn, 0.25)
    mix_at(out, timp * 0.9, st * SR)
    mix_at(out, cymbal(0.9) * 0.25, st * SR)
    out = fft_filter(out, hi=6500)
    out = reverb(out, wet=0.25, size=1.3, tail=0.0)
    out = out[: int(total * SR)]
    return out * adsr(len(out), 0.002, 0.01, 1.0, 0.3)


def make_whoosh():
    dur = 0.4
    n = int(dur * SR)
    t = np.arange(n) / SR
    x = rng.standard_normal(n)
    p = t / dur
    fc = 300 * (12 ** np.sin(np.pi * p * 0.9))      # sweep up then slightly back
    y = svf_bandpass(x, fc, q=1.3) + 0.4 * svf_bandpass(x, fc * 1.8, q=2.0)
    env = np.sin(np.pi * np.clip(p, 0, 1)) ** 1.6
    return y * env


def make_lifeline():
    total = 0.6
    out = np.zeros(int(total * SR))
    # quick ascending arpeggio (C major pentatonic, high register)
    freqs = [1046.5, 1318.5, 1568.0, 2093.0, 2637.0, 3136.0]
    for i, f in enumerate(freqs):
        st = i * 0.045
        n = int((total - st) * SR)
        tt = np.arange(n) / SR
        tone = (np.sin(2 * np.pi * f * tt) + 0.3 * np.sin(2 * np.pi * 2 * f * tt)) * np.exp(-tt / 0.18)
        tone[: int(0.002 * SR)] *= np.linspace(0, 1, int(0.002 * SR))
        mix_at(out, tone * (0.5 + 0.08 * i), st * SR)
    # shimmer: random tiny high sparkles
    n = len(out)
    sh = np.zeros(n)
    for _ in range(40):
        st = rng.random() * 0.5
        f = 3000 + rng.random() * 4500
        sn = int(0.05 * SR)
        tt = np.arange(sn) / SR
        mix_at(sh, np.sin(2 * np.pi * f * tt) * np.exp(-tt / 0.012) * 0.2, st * SR)
    t = np.arange(n) / SR
    out = out + sh * np.clip(t / 0.15, 0, 1)
    out *= 1 + 0.15 * np.sin(2 * np.pi * 14 * t)       # twinkle tremolo
    out = reverb(out, wet=0.3, size=0.6, tail=0.0)[:n]
    return out * adsr(n, 0.002, 0.01, 1.0, 0.15)


def make_buzz():
    dur = 0.35
    n = int(dur * SR)
    t = np.arange(n) / SR
    f = 220 * (1 + 0.5 * np.exp(-t / 0.012))           # punchy pitch drop on attack
    x = 0.55 * osc(f, n, "square") + 0.45 * osc(f * 1.5, n, "saw") + 0.3 * osc(f * 0.5, n, "square")
    x = fft_filter(x, hi=2600, order=2)
    click = fft_filter(rng.standard_normal(n), lo=2000, hi=8000) * exp_env(n, 0.004) * 0.6
    env = adsr(n, a=0.003, d=0.06, s=0.75, r=0.08)
    return x * env + click


def make_bonus_loop():
    """4 bars of 4/4 at 183.75 BPM; 1 sixteenth = exactly 1800 samples."""
    SIX = 1800
    total = 64 * SIX                       # 4 bars * 16 sixteenths
    out = np.zeros(total)

    def place(x, step, gain=1.0):
        # circular placement so tails wrap across the seam -> seamless loop
        s = (step * SIX) % total
        x = x * gain
        first = min(len(x), total - s)
        out[s:s + first] += x[:first]
        if len(x) > first:
            out[: len(x) - first] += x[first:]

    kn = int(0.22 * SR)
    kt = np.arange(kn) / SR
    kick = np.sin(2 * np.pi * np.cumsum(50 + 110 * np.exp(-kt / 0.025)) / SR) * exp_env(kn, 0.09)
    kick[: int(0.002 * SR)] *= np.linspace(0, 1, int(0.002 * SR))
    hn = int(0.04 * SR)
    hat = fft_filter(rng.standard_normal(hn), lo=7000, hi=10500) * exp_env(hn, 0.008)
    ohat = fft_filter(rng.standard_normal(int(0.12 * SR)), lo=6500, hi=10500) * exp_env(int(0.12 * SR), 0.04)
    cn = int(0.15 * SR)
    clap = np.zeros(cn)
    for off in (0, 0.009, 0.018):           # classic multi-burst clap
        b = rng.standard_normal(cn) * exp_env(cn, 0.012 if off < 0.018 else 0.05)
        mix_at(clap, b[: cn - int(off * SR)], off * SR)
    clap = fft_filter(clap, lo=900, hi=5000) + snare_hit(0.15, 200) * 0.5

    for bar in range(4):
        b = bar * 16
        for s in (0, 6, 8, 10 if bar % 2 else 11):       # kick pattern
            place(kick, b + s, 1.0)
        for s in (4, 12):
            place(clap, b + s, 0.55)
        for s in range(16):
            if s % 4 == 2:
                place(ohat, b + s, 0.22)
            elif s % 2 == 0:
                place(hat, b + s, 0.25)
            else:
                place(hat, b + s, 0.12)
        if bar == 3:                                     # fill at the end
            for s in (13, 14, 15):
                place(clap, b + s, 0.25 + 0.1 * (s - 13))

    # bass: root per bar (Am - F - C - G), eighth-note pulse with octave hops
    roots = [110.0, 87.31, 130.81, 98.0]
    for bar, r in enumerate(roots):
        for e in range(8):
            f = r * (2 if e % 4 == 3 else 1)
            n = 2 * SIX - 60
            tone = 0.6 * osc(f, n, "saw") + 0.5 * osc(f, n, "sine")
            tone = fft_filter(tone, hi=900, order=2)
            tone *= adsr(n, a=0.004, d=0.08, s=0.55, r=0.03)
            place(tone, bar * 16 + e * 2, 0.32)

    # light synth stab on off-beats for energy
    for bar, r in enumerate(roots):
        for s in (2, 6, 10, 14):
            n = int(0.09 * SR)
            chord = sum(osc(r * 4 * m, n, "saw") for m in (1, 1.26, 1.5))
            chord = fft_filter(chord, hi=2500) * exp_env(n, 0.03)
            place(chord, bar * 16 + s, 0.05)

    # gentle bus compression-ish soft clip, then make seam land exactly on zero
    out = np.tanh(out * 1.2) / np.tanh(1.2)
    # tiny crossfade-to-zero at the seam (64 samples ~ 3 ms) keeps edges at 0
    k = 64
    out[:k] *= np.sin(np.linspace(0, np.pi / 2, k)) ** 2
    out[-k:] *= np.cos(np.linspace(0, np.pi / 2, k)) ** 2
    out[0] = 0.0
    out[-1] = 0.0
    return out


SOUNDS = [
    ("tick.wav", make_tick, -1.0),
    ("correct.wav", make_correct, -1.0),
    ("wrong.wav", make_wrong, -1.0),
    ("timeup.wav", make_timeup, -1.0),
    ("drumroll.wav", make_drumroll, -1.0),
    ("applause.wav", make_applause, -1.0),
    ("fanfare.wav", make_fanfare, -1.0),
    ("whoosh.wav", make_whoosh, -1.0),
    ("lifeline.wav", make_lifeline, -1.0),
    ("bonus-loop.wav", make_bonus_loop, -6.0),
    ("buzz.wav", make_buzz, -1.0),
]


def main():
    for name, fn, pk in SOUNDS:
        x = fn()
        if name == "bonus-loop.wav":
            # normalize without the generic fade (loop edges handled above)
            x = normalize(x, pk)
            pcm = np.clip(np.round(x * 32767), -32768, 32767).astype("<i2")
            with wave.open(os.path.join(OUT, name), "wb") as w:
                w.setnchannels(1)
                w.setsampwidth(2)
                w.setframerate(SR)
                w.writeframes(pcm.tobytes())
        else:
            write(name, x, pk)
        print(f"wrote {name:16s} {len(x) / SR:5.2f}s")


if __name__ == "__main__":
    main()
