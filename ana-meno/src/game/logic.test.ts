import { describe, expect, it } from 'vitest';
import {
  ROOM_CODE_ALPHABET, ROOM_CODE_LENGTH, computeScore, cryptoRandomInt, formatDuration,
  generateRoomCode, isValidName, isValidRoomCode, normalizeRoomCode, pickSecretCharacters,
  sanitizeName,
} from './logic';

describe('room codes', () => {
  it('generates codes of the right length from the safe alphabet', () => {
    for (let i = 0; i < 200; i++) {
      const code = generateRoomCode();
      expect(code).toHaveLength(ROOM_CODE_LENGTH);
      for (const ch of code) expect(ROOM_CODE_ALPHABET).toContain(ch);
    }
  });

  it('never contains confusing characters (O/0, I/1, S/5)', () => {
    for (const ch of ['O', '0', 'I', '1', 'S', '5']) {
      expect(ROOM_CODE_ALPHABET).not.toContain(ch);
    }
  });

  it('normalizes case-insensitively and strips spaces', () => {
    expect(normalizeRoomCode(' x7k4p ')).toBe('X7K4P');
    expect(normalizeRoomCode('a b c d e')).toBe('ABCDE');
  });

  it('validates codes', () => {
    expect(isValidRoomCode('ABCDE')).toBe(true);
    expect(isValidRoomCode('abcde')).toBe(true);
    expect(isValidRoomCode('ABCD')).toBe(false);
    expect(isValidRoomCode('ABC10')).toBe(false); // 0 and 1 not in alphabet
    expect(isValidRoomCode('')).toBe(false);
  });
});

describe('names', () => {
  it('sanitizes whitespace and unsafe characters', () => {
    expect(sanitizeName('  علاء   الدين  ')).toBe('علاء الدين');
    expect(sanitizeName('<script>alert("x")</script>')).not.toContain('<');
    expect(sanitizeName('a'.repeat(50))).toHaveLength(20);
  });

  it('rejects empty or too-short names', () => {
    expect(isValidName('')).toBe(false);
    expect(isValidName('   ')).toBe(false);
    expect(isValidName('م')).toBe(false);
    expect(isValidName('ريم')).toBe(true);
  });
});

describe('secret character selection', () => {
  const ids = Array.from({ length: 30 }, (_, i) => i + 1);

  it('always picks two different characters', () => {
    for (let i = 0; i < 2000; i++) {
      const [a, b] = pickSecretCharacters(ids);
      expect(a).not.toBe(b);
      expect(ids).toContain(a);
      expect(ids).toContain(b);
    }
  });

  it('handles the adversarial rng edge (same index twice)', () => {
    // rand always returns 0 -> second pick must still differ.
    const [a, b] = pickSecretCharacters(ids, () => 0);
    expect(a).not.toBe(b);
  });

  it('cryptoRandomInt stays within bounds', () => {
    for (let i = 0; i < 500; i++) {
      const v = cryptoRandomInt(7);
      expect(v).toBeGreaterThanOrEqual(0);
      expect(v).toBeLessThan(7);
    }
  });
});

describe('scoring', () => {
  it('starts at 100 and deducts 5 per question, floor 20', () => {
    expect(computeScore(0, 10_000).base).toBe(100);
    expect(computeScore(4, 10_000).base).toBe(80);
    expect(computeScore(30, 10_000).base).toBe(20);
  });

  it('awards a decaying time bonus', () => {
    expect(computeScore(0, 0).timeBonus).toBe(50);
    expect(computeScore(0, 12).timeBonus).toBe(49);
    expect(computeScore(0, 600).timeBonus).toBe(0);
    expect(computeScore(0, 99999).timeBonus).toBe(0);
  });

  it('total = base + bonus', () => {
    const s = computeScore(6, 60);
    expect(s.total).toBe(s.base + s.timeBonus);
  });
});

describe('formatDuration', () => {
  it('formats mm:ss', () => {
    expect(formatDuration(0)).toBe('00:00');
    expect(formatDuration(65)).toBe('01:05');
    expect(formatDuration(600)).toBe('10:00');
  });
});
