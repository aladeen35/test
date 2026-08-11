/* ═══════════════════════════════════════════════
   مدرستنا — المؤثرات الصوتية (Web Audio API)
   جرس المدرسة، الطبشور، صح/غلط، تكتكة الوقت، الاحتفال
   ═══════════════════════════════════════════════ */

const Sound = (() => {
  let ctx = null;
  let enabled = true;

  function ac() {
    if (!ctx) ctx = new (window.AudioContext || window.webkitAudioContext)();
    if (ctx.state === 'suspended') ctx.resume();
    return ctx;
  }

  function tone({ freq = 440, type = 'sine', dur = 0.2, vol = 0.25, when = 0, slide = 0 }) {
    if (!enabled) return;
    const c = ac();
    const t0 = c.currentTime + when;
    const osc = c.createOscillator();
    const gain = c.createGain();
    osc.type = type;
    osc.frequency.setValueAtTime(freq, t0);
    if (slide) osc.frequency.exponentialRampToValueAtTime(Math.max(40, freq + slide), t0 + dur);
    gain.gain.setValueAtTime(0.0001, t0);
    gain.gain.exponentialRampToValueAtTime(vol, t0 + 0.015);
    gain.gain.exponentialRampToValueAtTime(0.0001, t0 + dur);
    osc.connect(gain).connect(c.destination);
    osc.start(t0);
    osc.stop(t0 + dur + 0.05);
  }

  function noise({ dur = 0.08, vol = 0.08, when = 0 }) {
    if (!enabled) return;
    const c = ac();
    const t0 = c.currentTime + when;
    const buf = c.createBuffer(1, c.sampleRate * dur, c.sampleRate);
    const data = buf.getChannelData(0);
    for (let i = 0; i < data.length; i++) data[i] = (Math.random() * 2 - 1) * (1 - i / data.length);
    const src = c.createBufferSource();
    src.buffer = buf;
    const gain = c.createGain();
    gain.gain.value = vol;
    const filter = c.createBiquadFilter();
    filter.type = 'highpass';
    filter.frequency.value = 3000;
    src.connect(filter).connect(gain).connect(c.destination);
    src.start(t0);
  }

  return {
    setEnabled(v) { enabled = v; },
    isEnabled() { return enabled; },

    /* جرس المدرسة: رنّات معدنية متتالية */
    bell() {
      for (let i = 0; i < 8; i++) {
        tone({ freq: 2200, type: 'square', dur: 0.05, vol: 0.12, when: i * 0.09 });
        tone({ freq: 1750, type: 'triangle', dur: 0.07, vol: 0.15, when: i * 0.09 + 0.02 });
      }
    },

    /* كتابة الطبشور على السبورة */
    chalk() {
      noise({ dur: 0.06, vol: 0.07 });
      noise({ dur: 0.05, vol: 0.05, when: 0.09 });
    },

    /* إجابة صحيحة */
    correct() {
      tone({ freq: 660, type: 'triangle', dur: 0.12, vol: 0.28 });
      tone({ freq: 880, type: 'triangle', dur: 0.16, vol: 0.28, when: 0.11 });
      tone({ freq: 1320, type: 'triangle', dur: 0.22, vol: 0.24, when: 0.22 });
    },

    /* إجابة خاطئة */
    wrong() {
      tone({ freq: 220, type: 'sawtooth', dur: 0.25, vol: 0.2, slide: -80 });
      tone({ freq: 165, type: 'sawtooth', dur: 0.3, vol: 0.18, when: 0.18, slide: -60 });
    },

    /* ضغطة الجرس في حصة الجرس */
    buzz() {
      tone({ freq: 1900, type: 'square', dur: 0.09, vol: 0.2 });
      tone({ freq: 1500, type: 'triangle', dur: 0.18, vol: 0.22, when: 0.06 });
    },

    /* تكتكة آخر ثوانٍ */
    tick() {
      tone({ freq: 1100, type: 'square', dur: 0.03, vol: 0.1 });
    },

    /* تقليب صفحة */
    page() {
      noise({ dur: 0.12, vol: 0.06 });
    },

    /* نقرة زر */
    click() {
      tone({ freq: 500, type: 'triangle', dur: 0.05, vol: 0.12 });
    },

    /* احتفال الفوز */
    fanfare() {
      const seq = [523, 659, 784, 1047, 784, 1047, 1319];
      seq.forEach((f, i) => tone({ freq: f, type: 'triangle', dur: 0.22, vol: 0.26, when: i * 0.16 }));
      for (let i = 0; i < 6; i++) {
        tone({ freq: 2200, type: 'square', dur: 0.05, vol: 0.08, when: 1.2 + i * 0.1 });
        tone({ freq: 1750, type: 'triangle', dur: 0.07, vol: 0.1, when: 1.2 + i * 0.1 + 0.02 });
      }
    },
  };
})();
