// Real online test: two isolated browser pages connect through the public PeerJS
// signaling server, the host starts a game and the player's answer reaches the host.
const { chromium } = require('playwright');
(async () => {
  const browser = await chromium.launch();
  const a = await (await browser.newContext()).newPage();
  const b = await (await browser.newContext()).newPage();
  const errors = [];
  for (const p of [a, b]) p.on('pageerror', e => errors.push(e.message));
  const U = 'http://localhost:8321/fullmark/index.html';
  await a.goto(U); await b.goto(U);

  // host
  await a.click('.mode-btn[data-mode="online"]');
  await a.fill('#playerName', 'Host'); await a.click('#startBtn');
  await a.fill('#lobbyName', 'Host'); await a.click('#lobbyHostBtn');
  await a.waitForFunction(() => /^\d{5}$/.test(document.getElementById('roomCode').textContent), null, { timeout: 30000 });
  const code = await a.textContent('#roomCode');
  console.log('room code:', code);

  // player
  await b.click('.mode-btn[data-mode="online"]');
  await b.fill('#playerName', 'Player'); await b.click('#startBtn');
  await b.fill('#lobbyName', 'Player'); await b.click('#lobbyJoinBtn');
  await b.fill('#joinCode', code); await b.click('#joinGoBtn');
  await a.waitForSelector('#lobbyStartBtn:not([disabled])', { timeout: 30000 });
  console.log('host status:', await a.textContent('#lobbyHostStatus'));

  await a.click('#lobbyStartBtn'); await a.click('#levelGoBtn'); await a.click('#startTimerBtn');
  await b.waitForSelector('#rmChoices .choice:not([disabled])', { timeout: 15000 });
  await b.click('#rmChoices .choice:nth-child(1)');
  await a.waitForSelector('#verdict.show', { timeout: 15000 });
  await b.waitForSelector('#rmVerdict.show', { timeout: 15000 });
  console.log('host verdict:', (await a.textContent('#verdict')).trim());
  console.log('player verdict:', (await b.textContent('#rmVerdict')).trim());
  await browser.close();
  if (errors.length) { console.error('JS errors:', errors); process.exit(1); }
  console.log('ONLINE TEST PASSED');
})().catch(e => { console.error(e); process.exit(1); });
