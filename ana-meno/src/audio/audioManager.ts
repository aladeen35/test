// Procedurally generated audio via WebAudio — no external or copyrighted
// assets. Respects browser autoplay rules: nothing plays before the first
// user interaction, and background music only starts from a user gesture.

export interface AudioPrefs {
  sounds: boolean; // master switch
  music: boolean;
  effects: boolean;
}

const PREFS_KEY = 'ana-meno-audio';

function loadPrefs(): AudioPrefs {
  try {
    const raw = localStorage.getItem(PREFS_KEY);
    if (raw) return { sounds: true, music: true, effects: true, ...JSON.parse(raw) };
  } catch { /* default */ }
  return { sounds: true, music: true, effects: true };
}

type EffectName =
  | 'click' | 'flip' | 'restore' | 'question' | 'answerYes' | 'answerNo'
  | 'join' | 'win' | 'lose' | 'guess' | 'tick';

class AudioManager {
  private ctx: AudioContext | null = null;
  private prefs: AudioPrefs = loadPrefs();
  private musicTimer: ReturnType<typeof setInterval> | null = null;
  private musicGain: GainNode | null = null;
  private musicStep = 0;
  private listeners = new Set<() => void>();

  getPrefs(): AudioPrefs {
    return { ...this.prefs };
  }

  subscribe(fn: () => void): () => void {
    this.listeners.add(fn);
    return () => this.listeners.delete(fn);
  }

  setPref<K extends keyof AudioPrefs>(key: K, value: boolean): void {
    this.prefs = { ...this.prefs, [key]: value };
    localStorage.setItem(PREFS_KEY, JSON.stringify(this.prefs));
    if (!this.musicAllowed()) this.stopMusic();
    this.listeners.forEach((fn) => fn());
  }

  toggleSounds(): void {
    this.setPref('sounds', !this.prefs.sounds);
  }

  private effectsAllowed(): boolean {
    return this.prefs.sounds && this.prefs.effects;
  }

  private musicAllowed(): boolean {
    return this.prefs.sounds && this.prefs.music;
  }

  private ensureCtx(): AudioContext | null {
    try {
      if (!this.ctx) {
        const Ctor = window.AudioContext ?? (window as unknown as { webkitAudioContext: typeof AudioContext }).webkitAudioContext;
        if (!Ctor) return null;
        this.ctx = new Ctor();
      }
      if (this.ctx.state === 'suspended') void this.ctx.resume();
      return this.ctx;
    } catch {
      return null;
    }
  }

  private tone(freq: number, start: number, duration: number, {
    type = 'sine' as OscillatorType, volume = 0.16, glide = 0,
  } = {}): void {
    const ctx = this.ctx;
    if (!ctx) return;
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.type = type;
    osc.frequency.setValueAtTime(freq, ctx.currentTime + start);
    if (glide) osc.frequency.exponentialRampToValueAtTime(Math.max(40, freq + glide), ctx.currentTime + start + duration);
    gain.gain.setValueAtTime(0, ctx.currentTime + start);
    gain.gain.linearRampToValueAtTime(volume, ctx.currentTime + start + 0.012);
    gain.gain.exponentialRampToValueAtTime(0.0008, ctx.currentTime + start + duration);
    osc.connect(gain).connect(ctx.destination);
    osc.start(ctx.currentTime + start);
    osc.stop(ctx.currentTime + start + duration + 0.05);
  }

  play(name: EffectName): void {
    if (!this.effectsAllowed()) return;
    if (!this.ensureCtx()) return;
    switch (name) {
      case 'click':
        this.tone(660, 0, 0.07, { type: 'triangle', volume: 0.12 });
        break;
      case 'flip':
        this.tone(320, 0, 0.1, { type: 'triangle', volume: 0.14, glide: -140 });
        break;
      case 'restore':
        this.tone(280, 0, 0.1, { type: 'triangle', volume: 0.12, glide: 160 });
        break;
      case 'question':
        this.tone(523, 0, 0.12, { type: 'sine', volume: 0.14 });
        this.tone(659, 0.1, 0.14, { type: 'sine', volume: 0.14 });
        this.tone(784, 0.2, 0.2, { type: 'sine', volume: 0.12 });
        break;
      case 'answerYes':
        this.tone(523, 0, 0.1, { volume: 0.15 });
        this.tone(784, 0.09, 0.18, { volume: 0.15 });
        break;
      case 'answerNo':
        this.tone(330, 0, 0.12, { volume: 0.15 });
        this.tone(247, 0.1, 0.2, { volume: 0.15 });
        break;
      case 'join':
        this.tone(440, 0, 0.1, { type: 'triangle', volume: 0.14 });
        this.tone(554, 0.08, 0.1, { type: 'triangle', volume: 0.14 });
        this.tone(659, 0.16, 0.18, { type: 'triangle', volume: 0.14 });
        break;
      case 'guess':
        this.tone(392, 0, 0.14, { type: 'sawtooth', volume: 0.07 });
        this.tone(494, 0.12, 0.14, { type: 'sawtooth', volume: 0.07 });
        break;
      case 'win': {
        const notes = [523, 659, 784, 1047, 784, 1047];
        notes.forEach((n, i) => this.tone(n, i * 0.11, 0.22, { type: 'triangle', volume: 0.16 }));
        break;
      }
      case 'lose':
        this.tone(392, 0, 0.18, { volume: 0.13 });
        this.tone(330, 0.16, 0.2, { volume: 0.13 });
        this.tone(262, 0.34, 0.3, { volume: 0.13 });
        break;
      case 'tick':
        this.tone(880, 0, 0.05, { type: 'square', volume: 0.05 });
        break;
    }
  }

  /** Cheerful ambient loop; call only from a user-gesture handler. */
  startMusic(): void {
    if (!this.musicAllowed() || this.musicTimer) return;
    const ctx = this.ensureCtx();
    if (!ctx) return;
    this.musicGain = ctx.createGain();
    this.musicGain.gain.value = 0.045;
    this.musicGain.connect(ctx.destination);

    // Simple I–vi–IV–V arpeggio in C major, light and non-distracting.
    const chords = [
      [261.6, 329.6, 392.0],
      [220.0, 261.6, 329.6],
      [174.6, 220.0, 261.6],
      [196.0, 246.9, 293.7],
    ];
    const stepDur = 0.42;
    const playStep = () => {
      if (!this.ctx || !this.musicGain) return;
      const chord = chords[Math.floor(this.musicStep / 4) % chords.length];
      const note = chord[this.musicStep % 3];
      const osc = this.ctx.createOscillator();
      const g = this.ctx.createGain();
      osc.type = 'triangle';
      osc.frequency.value = note * (this.musicStep % 8 === 7 ? 2 : 1);
      g.gain.setValueAtTime(0, this.ctx.currentTime);
      g.gain.linearRampToValueAtTime(1, this.ctx.currentTime + 0.03);
      g.gain.exponentialRampToValueAtTime(0.001, this.ctx.currentTime + stepDur);
      osc.connect(g).connect(this.musicGain);
      osc.start();
      osc.stop(this.ctx.currentTime + stepDur + 0.05);
      this.musicStep += 1;
    };
    playStep();
    this.musicTimer = setInterval(playStep, stepDur * 1000);
  }

  stopMusic(): void {
    if (this.musicTimer) {
      clearInterval(this.musicTimer);
      this.musicTimer = null;
    }
    this.musicGain?.disconnect();
    this.musicGain = null;
  }

  isMusicPlaying(): boolean {
    return this.musicTimer !== null;
  }
}

export const audio = new AudioManager();
