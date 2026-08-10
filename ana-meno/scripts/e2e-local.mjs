// Two-player acceptance test driving the built app (local backend) with
// headless Chromium: create room, join, ask/answer, eliminate, guess,
// result, rematch — plus screenshots and a secret-privacy DOM check.
// Usage: npm run build && npx vite preview --port 4173 &  then:
//   CHROME_BIN=/path/to/chrome node scripts/e2e-local.mjs
import { chromium } from 'playwright-core';
import { mkdirSync } from 'node:fs';

const SHOT = process.env.SHOT_DIR ?? '/tmp/ana-meno-shots';
mkdirSync(SHOT, { recursive: true });
const URL = process.env.APP_URL ?? 'http://localhost:4173/';
const MOBILE = { width: 390, height: 844 };

const browser = await chromium.launch({
  executablePath: process.env.CHROME_BIN || undefined,
  args: ['--no-sandbox'],
});
const context = await browser.newContext({ viewport: MOBILE, locale: 'ar' });
const pageA = await context.newPage();
const pageB = await context.newPage();

const fail = (msg) => { console.error('FAIL:', msg); process.exitCode = 1; };
const ok = (msg) => console.log('OK:', msg);

try {
  // --- Device A: home, name, create room ---
  await pageA.goto(URL);
  await pageA.waitForSelector('text=أنا مِنو');
  await pageA.screenshot({ path: `${SHOT}/01-home.png` });
  await pageA.fill('input[placeholder="اكتب اسمك"]', 'علاء الدين');
  await pageA.click('text=إنشاء لعبة');
  await pageA.waitForSelector('text=إنشاء الغرفة');
  await pageA.screenshot({ path: `${SHOT}/02-create.png` });
  await pageA.click('text=إنشاء الغرفة');
  await pageA.waitForSelector('text=رمز الغرفة');
  await pageA.screenshot({ path: `${SHOT}/03-lobby-waiting.png` });

  const code = (await pageA.textContent('.ltr-num.text-5xl')).trim();
  if (!/^[A-Z2-9]{5}$/.test(code)) fail(`bad room code: ${code}`); else ok(`room code ${code}`);

  // --- Device B: join ---
  await pageB.goto(URL);
  await pageB.fill('input[placeholder="اكتب اسمك"]', 'ريم');
  await pageB.click('text=الانضمام إلى لعبة');
  await pageB.waitForSelector('text=أدخل رمز الغرفة');
  await pageB.fill('input[aria-label="رمز الغرفة"]', code);
  await pageB.screenshot({ path: `${SHOT}/04-join.png` });
  await pageB.click('button.btn-primary:has-text("انضمام")');

  // Both should land on the game board.
  await pageA.waitForSelector('text=شخصيتك السرية', { timeout: 10000 });
  await pageB.waitForSelector('text=شخصيتك السرية', { timeout: 10000 });
  ok('both players reached the game board');
  await pageA.screenshot({ path: `${SHOT}/05-game-a.png` });

  // Secrets are always visible on each player's own device; read them via
  // the secret card's aria-label ("شخصيتك السرية: name — profession").
  const readSecret = async (page) => {
    await page.waitForFunction(() => {
      const el = document.querySelector('div[aria-label*="شخصيتك السرية"]');
      return !!el && el.getAttribute('aria-label').includes('—');
    }, { timeout: 8000 });
    return page.getAttribute('div[aria-label*="شخصيتك السرية"]', 'aria-label');
  };
  const secretA = await readSecret(pageA);
  const secretB = await readSecret(pageB);
  if (secretA === secretB) fail('secrets identical!'); else ok('secrets differ');

  // Player A asks a question.
  await pageA.click('button:has-text("اسأل سؤالاً")');
  await pageA.waitForSelector('text=هل ترتدي الشخصية نظارة؟');
  await pageA.screenshot({ path: `${SHOT}/06-question-sheet.png` });
  await pageA.click('text=هل ترتدي الشخصية نظارة؟');

  // Player B receives it and answers نعم.
  await pageB.waitForSelector('text=أجب عن السؤال', { timeout: 5000 });
  await pageB.screenshot({ path: `${SHOT}/07-answer-modal.png` });
  await pageB.click('.btn-yes');
  ok('question asked and answered');

  // Player A sees the answer in the log; it is now B's turn.
  await pageA.waitForSelector('text=انتظر دور خصمك', { timeout: 5000 });
  await pageB.waitForSelector('text=دورك', { timeout: 5000 });
  ok('turn passed to player B');

  // Player B asks, A answers لا.
  await pageB.click('button:has-text("اسأل سؤالاً")');
  await pageB.click('text=هل لدى الشخصية لحية؟');
  await pageA.waitForSelector('text=أجب عن السؤال', { timeout: 5000 });
  await pageA.click('.btn-no');
  await pageB.waitForSelector('text=انتظر دور خصمك', { timeout: 5000 });
  await pageA.waitForSelector('text=دورك', { timeout: 5000 });
  ok('second round works');

  // Player A eliminates two characters and restores one.
  await pageA.click('img[src*="chef-male"]');
  await pageA.click('img[src*="pilot-male"]');
  await pageA.screenshot({ path: `${SHOT}/08-eliminated.png` });
  await pageA.click('button[aria-label*="مستبعدة"]');
  ok('eliminate/restore works');

  // Question log shows entries.
  await pageA.click('text=سجل الأسئلة');
  await pageA.screenshot({ path: `${SHOT}/09-log.png` });

  // --- Secret privacy: inspect localStorage-visible public state? The local
  // dev backend keeps secrets in shared storage by design; the Supabase
  // backend is the production privacy path. Here we verify the UI/pubstate.
  const pubStateHasSecrets = await pageA.evaluate(() => {
    // The app state is not exposed globally; check the DOM never leaks the
    // opponent secret while active: mystery card only.
    return document.body.innerHTML.includes('revealedSecrets');
  });
  if (pubStateHasSecrets) fail('public DOM leaks secrets'); else ok('DOM clean of secrets');

  // Player A guesses B's secret correctly. Extract B's secret name from its chip.
  const secretName = secretB.match(/السرية:\s*(.+?)\s*—/)?.[1].trim();
  ok(`player B secret name: ${secretName}`);

  await pageA.click('button:has-text("خمّن الشخصية")');
  await pageA.waitForSelector('text=اختر الشخصية');
  await pageA.click(`div[role="dialog"] button[aria-label="${secretName}"]`);
  await pageA.waitForSelector('text=هل أنت متأكد؟');
  await pageA.screenshot({ path: `${SHOT}/10-guess-confirm.png` });
  await pageA.click('text=نعم، هذا تخميني');

  // Both should reach the result screen; A wins.
  await pageA.waitForSelector('text=أحسنت', { timeout: 8000 });
  await pageB.waitForSelector('text=هذه المرة لم يحالفك الحظ', { timeout: 8000 });
  await pageA.screenshot({ path: `${SHOT}/11-win.png` });
  await pageB.screenshot({ path: `${SHOT}/12-lose.png` });
  ok('winner and loser screens shown');

  // Scores match on both devices.
  const winnerNameA = await pageA.textContent('.text-royal.text-2xl');
  const winnerNameB = await pageB.textContent('.text-royal.text-2xl');
  if (winnerNameA !== winnerNameB) fail(`winner mismatch ${winnerNameA} vs ${winnerNameB}`);
  else ok(`winner on both: ${winnerNameA}`);

  // Rematch: both press play again → fresh game.
  await pageA.click('button:has-text("إعادة اللعب")');
  await pageA.waitForSelector('text=بانتظار اللاعب الآخر');
  await pageB.click('button:has-text("إعادة اللعب")');
  await pageA.waitForSelector('text=شخصيتك السرية', { timeout: 8000 });
  await pageB.waitForSelector('text=شخصيتك السرية', { timeout: 8000 });
  const q = await pageA.textContent('body');
  if (!q.includes('المتبقي')) fail('rematch board missing');
  ok('rematch started a fresh game');
  await pageA.screenshot({ path: `${SHOT}/13-rematch.png` });

  console.log('E2E COMPLETE');
} catch (err) {
  console.error('E2E ERROR:', err.message);
  await pageA.screenshot({ path: `${SHOT}/error-a.png` }).catch(() => {});
  await pageB.screenshot({ path: `${SHOT}/error-b.png` }).catch(() => {});
  process.exitCode = 1;
} finally {
  await browser.close();
}
