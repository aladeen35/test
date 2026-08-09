// Pure game rules: room codes, scoring, secret assignment. No IO here.

export const ROOM_CODE_LENGTH = 5;
// Avoids visually confusing characters (O/0, I/1, S/5).
export const ROOM_CODE_ALPHABET = 'ABCDEFGHJKLMNPQRTUVWXYZ2346789';

export const TURN_SECONDS = 90;
export const BASE_SCORE = 100;
export const QUESTION_PENALTY = 5;
export const MIN_BASE_SCORE = 20;
export const MAX_TIME_BONUS = 50;
/** Time bonus decays by 1 point every N seconds of match time. */
export const TIME_BONUS_DECAY_SECONDS = 12;
/** A room that never starts expires after this long. */
export const ROOM_TTL_MINUTES = 60;

export type RandomInt = (maxExclusive: number) => number;

/** Default RNG backed by Web Crypto (available in browsers and Node). */
export const cryptoRandomInt: RandomInt = (maxExclusive) => {
  const buf = new Uint32Array(1);
  // Rejection sampling to avoid modulo bias.
  const limit = Math.floor(0xffffffff / maxExclusive) * maxExclusive;
  let x: number;
  do {
    globalThis.crypto.getRandomValues(buf);
    x = buf[0];
  } while (x >= limit);
  return x % maxExclusive;
};

export function generateRoomCode(rand: RandomInt = cryptoRandomInt): string {
  let code = '';
  for (let i = 0; i < ROOM_CODE_LENGTH; i++) {
    code += ROOM_CODE_ALPHABET[rand(ROOM_CODE_ALPHABET.length)];
  }
  return code;
}

/** Room codes are case-insensitive; strip spaces and Arabic-digit lookalikes. */
export function normalizeRoomCode(input: string): string {
  return input.trim().toUpperCase().replace(/\s+/g, '');
}

export function isValidRoomCode(code: string): boolean {
  const normalized = normalizeRoomCode(code);
  if (normalized.length !== ROOM_CODE_LENGTH) return false;
  return [...normalized].every((ch) => ROOM_CODE_ALPHABET.includes(ch));
}

export const MAX_NAME_LENGTH = 20;

/** Sanitize a display name: trim, collapse spaces, cap length. */
export function sanitizeName(input: string): string {
  return input.replace(/[<>"'`]/g, '').replace(/\s+/g, ' ').trim().slice(0, MAX_NAME_LENGTH);
}

export function isValidName(input: string): boolean {
  return sanitizeName(input).length >= 2;
}

/**
 * Picks two DIFFERENT secret character ids for the two players.
 * Returns [player1SecretId, player2SecretId].
 */
export function pickSecretCharacters(
  characterIds: number[],
  rand: RandomInt = cryptoRandomInt,
): [number, number] {
  if (characterIds.length < 2) throw new Error('Need at least two characters');
  const first = rand(characterIds.length);
  let second = rand(characterIds.length - 1);
  if (second >= first) second += 1; // guarantees second !== first
  return [characterIds[first], characterIds[second]];
}

export interface ScoreBreakdown {
  base: number;
  timeBonus: number;
  total: number;
}

/** finalScore = max(20, 100 - questions*5) + timeBonus */
export function computeScore(questionsUsed: number, elapsedSeconds: number): ScoreBreakdown {
  const base = Math.max(MIN_BASE_SCORE, BASE_SCORE - questionsUsed * QUESTION_PENALTY);
  const timeBonus = Math.max(
    0,
    MAX_TIME_BONUS - Math.floor(Math.max(0, elapsedSeconds) / TIME_BONUS_DECAY_SECONDS),
  );
  return { base, timeBonus, total: base + timeBonus };
}

export function formatDuration(totalSeconds: number): string {
  const s = Math.max(0, Math.floor(totalSeconds));
  const m = Math.floor(s / 60);
  const r = s % 60;
  return `${String(m).padStart(2, '0')}:${String(r).padStart(2, '0')}`;
}
