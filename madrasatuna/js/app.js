/* ═══════════════════════════════════════════════
   مدرستنا — محرك اللعبة
   المضيف (الأستاذ) يدير الأسئلة والاحتساب،
   وفريقان يتنافسان عبر حصص متتالية.
   ═══════════════════════════════════════════════ */

(() => {
  'use strict';

  const $ = (sel) => document.querySelector(sel);
  const $$ = (sel) => [...document.querySelectorAll(sel)];

  /* ─────────── حالة اللعبة ─────────── */
  const state = {
    host: 'أستاذ عدوي',
    teams: [
      { name: '', mascot: MASCOTS[0], score: 0 },
      { name: '', mascot: MASCOTS[1], score: 0 },
    ],
    roundsCount: 5,
    rounds: [],          // الحصص المختارة لهذه اللعبة
    roundIndex: 0,
    // حالة الحصة الجارية
    queue: [],           // أسئلة الحصة
    qIndex: 0,
    turn: 0,             // الفريق صاحب الدور
    timerId: null,
    timeLeft: 0,
    buzzedTeam: null,
    buzzSecondChance: false,
    tabooGot: 0,
    tabooTeamsDone: 0,
    revealed: false,
  };

  const shuffle = (arr) => {
    const a = [...arr];
    for (let i = a.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [a[i], a[j]] = [a[j], a[i]];
    }
    return a;
  };

  /* ─────────── التنقل بين الشاشات ─────────── */
  function show(id) {
    $$('.screen').forEach((s) => s.classList.remove('active'));
    $(id).classList.add('active');
    window.scrollTo(0, 0);
  }

  function stopTimer() {
    if (state.timerId) { clearInterval(state.timerId); state.timerId = null; }
  }

  /* ─────────── شاشة الإعداد ─────────── */
  function renderMascots() {
    [0, 1].forEach((t) => {
      const row = $(`#mascots-${t}`);
      row.innerHTML = '';
      MASCOTS.forEach((m, i) => {
        const btn = document.createElement('button');
        btn.type = 'button';
        btn.className = 'mascot' + (state.teams[t].mascot === m ? ' active' : '');
        btn.textContent = `${m.icon} ${m.name}`;
        btn.addEventListener('click', () => {
          state.teams[t].mascot = MASCOTS[i];
          Sound.chalk();
          renderMascots();
        });
        row.appendChild(btn);
      });
    });
  }

  function startGame() {
    const t1 = $('#team1-name').value.trim();
    const t2 = $('#team2-name').value.trim();
    state.host = $('#host-name').value.trim() || 'أستاذ عدوي';
    state.teams[0].name = t1 || state.teams[0].mascot.name;
    state.teams[1].name = t2 || state.teams[1].mascot.name;
    state.teams[0].score = 0;
    state.teams[1].score = 0;
    state.roundIndex = 0;
    state.turn = 0;

    // 4 حصص = بدون «فاكر ولا ناسي»، 5 حصص = الكل
    state.rounds = state.roundsCount === 5
      ? [...ROUNDS]
      : ROUNDS.filter((r) => r.id !== 'nostalgia');

    Sound.bell();
    showRoundIntro();
  }

  /* ─────────── مقدمة الحصة ─────────── */
  function showRoundIntro() {
    const r = state.rounds[state.roundIndex];
    $('#intro-number').textContent = ROUND_ORDINALS[state.roundIndex];
    $('#intro-title').textContent = `${r.icon} ${r.title}`;
    $('#intro-desc').textContent = r.desc;
    $('#intro-points').textContent = r.points;
    show('#screen-round-intro');
  }

  function beginRound() {
    const r = state.rounds[state.roundIndex];
    Sound.bell();
    if (r.type === 'quiz') beginQuiz(r);
    else if (r.type === 'buzzer') beginBuzzer(r);
    else if (r.type === 'taboo') beginTaboo(r);
  }

  /* ─────────── رأس النتيجة المشترك ─────────── */
  function renderScores(prefix) {
    [0, 1].forEach((t) => {
      const tab = $(`#${prefix}-${t}`);
      tab.querySelector('.score-mascot').textContent = state.teams[t].mascot.icon;
      tab.querySelector('.score-name').textContent = state.teams[t].name;
      tab.querySelector('.score-value').textContent = state.teams[t].score;
    });
  }

  function markTurn(prefix) {
    [0, 1].forEach((t) => $(`#${prefix}-${t}`).classList.toggle('turn-glow', state.turn === t));
  }

  /* ═══════════ نمط الأسئلة (حصص 1، 2، 5) ═══════════ */
  function beginQuiz(r) {
    state.queue = shuffle(r.bank()).slice(0, r.perTeam * 2);
    state.qIndex = 0;
    show('#screen-question');
    $('#q-round-label').textContent = `${r.icon} ${r.title}`;
    nextQuizQuestion();
  }

  function nextQuizQuestion() {
    const r = state.rounds[state.roundIndex];
    if (state.qIndex >= state.queue.length) return endRound();

    state.revealed = false;
    const item = state.queue[state.qIndex];
    renderScores('score-tab');
    markTurn('score-tab');
    $('#turn-banner').textContent = `🎤 الدور على: ${state.teams[state.turn].mascot.icon} ${state.teams[state.turn].name}`;
    $('#q-counter').textContent = `سؤال ${state.qIndex + 1} من ${state.queue.length}`;
    $('#q-text').textContent = item.q;
    $('#q-answer').textContent = item.a;
    $('#q-answer').classList.add('hidden');
    $('#btn-reveal').classList.remove('hidden');
    Sound.page();
    startCountdown(r.timer, '#q-timer', () => {
      Sound.wrong();
      judge(false, true);
    });
  }

  function reveal() {
    state.revealed = true;
    $('#q-answer').classList.remove('hidden');
    $('#btn-reveal').classList.add('hidden');
    Sound.chalk();
  }

  function judge(correct, timedOut = false) {
    stopTimer();
    const r = state.rounds[state.roundIndex];
    if (correct) {
      state.teams[state.turn].score += r.score;
      Sound.correct();
    } else if (!timedOut) {
      Sound.wrong();
    }
    state.turn = 1 - state.turn;
    state.qIndex += 1;
    setTimeout(nextQuizQuestion, correct ? 500 : 400);
  }

  /* ═══════════ حصة الجرس ═══════════ */
  function beginBuzzer(r) {
    state.queue = shuffle(r.bank()).slice(0, r.total);
    state.qIndex = 0;
    show('#screen-buzzer');
    $('#buzz-pad-0 span').textContent = state.teams[0].name;
    $('#buzz-pad-1 span').textContent = state.teams[1].name;
    nextBuzzerQuestion();
  }

  function nextBuzzerQuestion() {
    if (state.qIndex >= state.queue.length) return endRound();
    const item = state.queue[state.qIndex];
    state.buzzedTeam = null;
    state.buzzSecondChance = false;
    renderScores('bz-score');
    $$('#bz-score-0, #bz-score-1').forEach((el) => el.classList.remove('turn-glow'));
    $('#bz-counter').textContent = `سؤال ${state.qIndex + 1} من ${state.queue.length}`;
    $('#bz-text').textContent = item.q;
    $('#bz-answer').textContent = item.a;
    $('#bz-answer').classList.add('hidden');
    $('#bz-reveal').classList.add('hidden');
    $('#buzz-status').textContent = 'استعدوا… أول جرس يجاوب! 👇';
    $('#bz-controls').classList.add('hidden');
    [0, 1].forEach((t) => {
      const pad = $(`#buzz-pad-${t}`);
      pad.disabled = false;
      pad.classList.remove('buzzed');
    });
    Sound.page();
  }

  function buzz(team) {
    if (state.buzzedTeam !== null) return;
    state.buzzedTeam = team;
    Sound.buzz();
    $(`#buzz-pad-${team}`).classList.add('buzzed');
    $(`#buzz-pad-${1 - team}`).disabled = true;
    $(`#bz-score-${team}`).classList.add('turn-glow');
    $('#buzz-status').textContent = `🔔 ${state.teams[team].mascot.icon} ${state.teams[team].name} ضرب الجرس! جاوبوا يا أبطال…`;
    $('#bz-reveal').classList.remove('hidden');
    $('#bz-controls').classList.remove('hidden');
  }

  function buzzerReveal() {
    $('#bz-answer').classList.remove('hidden');
    $('#bz-reveal').classList.add('hidden');
    Sound.chalk();
  }

  function buzzerJudge(correct) {
    const r = state.rounds[state.roundIndex];
    const team = state.buzzedTeam;
    if (correct) {
      state.teams[team].score += r.score;
      Sound.correct();
      state.qIndex += 1;
      setTimeout(nextBuzzerQuestion, 500);
      return;
    }
    // غلط: خصم، وإتاحة فرصة للفريق الثاني إن لم تُستهلك
    state.teams[team].score -= r.penalty;
    Sound.wrong();
    renderScores('bz-score');
    if (!state.buzzSecondChance) {
      state.buzzSecondChance = true;
      const other = 1 - team;
      state.buzzedTeam = other;
      $(`#bz-score-${team}`).classList.remove('turn-glow');
      $(`#bz-score-${other}`).classList.add('turn-glow');
      $('#bz-answer').classList.add('hidden');
      $('#bz-reveal').classList.remove('hidden');
      $('#buzz-status').textContent = `↩️ السؤال عدّى لفريق ${state.teams[other].mascot.icon} ${state.teams[other].name}!`;
    } else {
      state.qIndex += 1;
      setTimeout(nextBuzzerQuestion, 500);
    }
  }

  function buzzerSkip() {
    Sound.page();
    state.qIndex += 1;
    nextBuzzerQuestion();
  }

  /* ═══════════ قول ولا تقولش ═══════════ */
  function beginTaboo(r) {
    state.queue = shuffle(r.bank());
    state.qIndex = 0;
    state.tabooTeamsDone = 0;
    state.turn = 0;
    show('#screen-taboo');
    prepareTabooTurn();
  }

  function prepareTabooTurn() {
    const r = state.rounds[state.roundIndex];
    state.tabooGot = 0;
    renderScores('tb-score');
    markTurn('tb-score');
    $('#tb-turn').textContent = `🎭 دور فريق: ${state.teams[state.turn].mascot.icon} ${state.teams[state.turn].name} — اختاروا لاعبًا يوصّف!`;
    $('#tb-got').textContent = 'أصاب: 0';
    $('#tb-timer').textContent = r.timer;
    $('#tb-timer').classList.remove('danger');
    $('#tb-word').textContent = '؟؟؟';
    $('#tb-forbidden').textContent = '—';
    $('#tb-start').classList.remove('hidden');
    $$('#screen-taboo .host-controls .btn').forEach((b) => (b.disabled = true));
  }

  function tabooStart() {
    const r = state.rounds[state.roundIndex];
    $('#tb-start').classList.add('hidden');
    $$('#screen-taboo .host-controls .btn').forEach((b) => (b.disabled = false));
    Sound.bell();
    showTabooWord();
    startCountdown(r.timer, '#tb-timer', endTabooTurn);
  }

  function showTabooWord() {
    if (state.qIndex >= state.queue.length) state.qIndex = 0; // إعادة تدوير عند النفاد
    const item = state.queue[state.qIndex];
    $('#tb-word').textContent = item.word;
    $('#tb-forbidden').textContent = item.forbidden;
    Sound.page();
  }

  function tabooCorrect() {
    const r = state.rounds[state.roundIndex];
    state.tabooGot += 1;
    state.teams[state.turn].score += r.score;
    $('#tb-got').textContent = `أصاب: ${state.tabooGot}`;
    renderScores('tb-score');
    Sound.correct();
    state.qIndex += 1;
    showTabooWord();
  }

  function tabooPass() {
    Sound.page();
    state.qIndex += 1;
    showTabooWord();
  }

  function endTabooTurn() {
    stopTimer();
    Sound.bell();
    state.tabooTeamsDone += 1;
    if (state.tabooTeamsDone >= 2) return endRound();
    state.turn = 1 - state.turn;
    prepareTabooTurn();
  }

  /* ─────────── المؤقّت المشترك ─────────── */
  function startCountdown(seconds, sel, onEnd) {
    stopTimer();
    state.timeLeft = seconds;
    const el = $(sel);
    el.textContent = seconds;
    el.classList.remove('danger');
    state.timerId = setInterval(() => {
      state.timeLeft -= 1;
      el.textContent = state.timeLeft;
      if (state.timeLeft <= 5 && state.timeLeft > 0) {
        el.classList.add('danger');
        Sound.tick();
      }
      if (state.timeLeft <= 0) {
        stopTimer();
        Sound.bell();
        onEnd();
      }
    }, 1000);
  }

  /* ─────────── نهاية الحصة / لوحة النتائج ─────────── */
  function endRound() {
    stopTimer();
    const isLast = state.roundIndex >= state.rounds.length - 1;
    if (isLast) return showWinner();

    const [a, b] = state.teams;
    $('#sb-title').textContent = `📊 النتيجة بعد ${ROUND_ORDINALS[state.roundIndex]}`;
    [0, 1].forEach((t) => {
      const row = $(`#sb-row-${t}`);
      row.querySelector('.sb-mascot').textContent = state.teams[t].mascot.icon;
      row.querySelector('.sb-name').textContent = state.teams[t].name;
      row.querySelector('.sb-score').textContent = state.teams[t].score;
      row.classList.remove('leader');
    });
    if (a.score !== b.score) {
      $(`#sb-row-${a.score > b.score ? 0 : 1}`).classList.add('leader');
    }
    const diff = Math.abs(a.score - b.score);
    const pool = diff === 0 ? SCORE_COMMENTS.tie : diff <= 15 ? SCORE_COMMENTS.close : SCORE_COMMENTS.far;
    $('#sb-comment').textContent = pool[Math.floor(Math.random() * pool.length)];
    Sound.bell();
    show('#screen-scoreboard');
  }

  function nextRound() {
    state.roundIndex += 1;
    showRoundIntro();
  }

  /* ─────────── شاشة الفائز ─────────── */
  function showWinner() {
    const [a, b] = state.teams;
    const tie = a.score === b.score;
    const winner = a.score >= b.score ? state.teams[0] : state.teams[1];

    $('#winner-team').textContent = tie
      ? '🤝 تعادل الأبطال!'
      : `${winner.mascot.icon} ${winner.name}`;
    $('.winner-title').textContent = tie ? 'مفيش خسران النهارده!' : 'بطل مدرستنا!';
    $('#winner-cheer').textContent = tie
      ? `${state.host} بيقول: الإيد على الإيد… والماتش يتعاد! 😄`
      : `«${winner.mascot.cheer}»`;
    $('#winner-scores').textContent =
      `${a.mascot.icon} ${a.name}: ${a.score} نقطة  —  ${b.mascot.icon} ${b.name}: ${b.score} نقطة`;

    show('#screen-winner');
    Sound.fanfare();
    launchConfetti();
  }

  /* ─────────── قصاصات الاحتفال ─────────── */
  let confettiRAF = null;
  function launchConfetti() {
    const canvas = $('#confetti');
    const dpr = window.devicePixelRatio || 1;
    canvas.width = canvas.offsetWidth * dpr;
    canvas.height = canvas.offsetHeight * dpr;
    const g = canvas.getContext('2d');
    g.scale(dpr, dpr);
    const W = canvas.offsetWidth, H = canvas.offsetHeight;
    const colors = ['#FFC93C', '#F77F00', '#E63946', '#2E86DE', '#06A77D', '#FDFDF4'];
    const bits = Array.from({ length: 130 }, () => ({
      x: Math.random() * W, y: -20 - Math.random() * H,
      w: 6 + Math.random() * 7, h: 9 + Math.random() * 8,
      vy: 1.6 + Math.random() * 2.6, vx: -1 + Math.random() * 2,
      rot: Math.random() * Math.PI, vr: -0.08 + Math.random() * 0.16,
      color: colors[Math.floor(Math.random() * colors.length)],
    }));
    cancelAnimationFrame(confettiRAF);
    const started = performance.now();
    (function frame(now) {
      g.clearRect(0, 0, W, H);
      bits.forEach((p) => {
        p.y += p.vy; p.x += p.vx; p.rot += p.vr;
        if (p.y > H + 20) { p.y = -20; p.x = Math.random() * W; }
        g.save();
        g.translate(p.x, p.y);
        g.rotate(p.rot);
        g.fillStyle = p.color;
        g.fillRect(-p.w / 2, -p.h / 2, p.w, p.h);
        g.restore();
      });
      if (now - started < 12000 && $('#screen-winner').classList.contains('active')) {
        confettiRAF = requestAnimationFrame(frame);
      } else {
        g.clearRect(0, 0, W, H);
      }
    })(started);
  }

  /* ─────────── إعادة اللعب ─────────── */
  function rematch() {
    state.teams[0].score = 0;
    state.teams[1].score = 0;
    state.roundIndex = 0;
    state.turn = 0;
    Sound.bell();
    showRoundIntro();
  }

  /* ─────────── ربط الأحداث ─────────── */
  const actions = {
    'new-game': () => { Sound.click(); renderMascots(); show('#screen-setup'); },
    'how-to': () => { Sound.page(); show('#screen-howto'); },
    'go-home': () => { stopTimer(); Sound.click(); show('#screen-home'); },
    'toggle-sound': () => {
      Sound.setEnabled(!Sound.isEnabled());
      $('#btn-sound').textContent = Sound.isEnabled() ? '🔊 الصوت: شغّال' : '🔇 الصوت: مقفول';
      Sound.click();
    },
    'start-game': startGame,
    'begin-round': beginRound,
    'reveal': reveal,
    'judge-correct': () => judge(true),
    'judge-wrong': () => judge(false),
    'judge-skip': () => { Sound.page(); judge(false, true); },
    'bz-reveal': buzzerReveal,
    'bz-correct': () => buzzerJudge(true),
    'bz-wrong': () => buzzerJudge(false),
    'bz-skip': buzzerSkip,
    'tb-start': tabooStart,
    'tb-correct': tabooCorrect,
    'tb-pass': tabooPass,
    'next-round': nextRound,
    'rematch': rematch,
  };

  document.addEventListener('click', (e) => {
    const btn = e.target.closest('[data-action]');
    if (btn && actions[btn.dataset.action]) actions[btn.dataset.action]();
  });

  $('#buzz-pad-0').addEventListener('click', () => buzz(0));
  $('#buzz-pad-1').addEventListener('click', () => buzz(1));

  $$('.rounds-choice .chip').forEach((chip) => {
    chip.addEventListener('click', () => {
      $$('.rounds-choice .chip').forEach((c) => c.classList.remove('active'));
      chip.classList.add('active');
      state.roundsCount = Number(chip.dataset.rounds);
      Sound.chalk();
    });
  });

  renderMascots();
})();
