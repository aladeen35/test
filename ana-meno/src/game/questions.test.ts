import { describe, expect, it } from 'vitest';
import { CHARACTERS } from './characters';
import { QUESTIONS, answerFor, getQuestion, isValidQuestionId } from './questions';

describe('character roster', () => {
  it('contains exactly 30 characters with unique ids, slugs and names', () => {
    expect(CHARACTERS).toHaveLength(30);
    expect(new Set(CHARACTERS.map((c) => c.id)).size).toBe(30);
    expect(new Set(CHARACTERS.map((c) => c.slug)).size).toBe(30);
    expect(new Set(CHARACTERS.map((c) => c.name)).size).toBe(30);
  });

  it('has a balanced gender mix', () => {
    const males = CHARACTERS.filter((c) => c.gender === 'male').length;
    expect(males).toBe(15);
  });

  it('has 30 distinct Arabic professions', () => {
    // English keys are shared between male/female variants (doctor m/f);
    // the Arabic labels are all distinct (طبيب / طبيبة).
    expect(new Set(CHARACTERS.map((c) => c.professionAr)).size).toBe(30);
  });

  it('every character has Arabic name and visual traits', () => {
    for (const c of CHARACTERS) {
      expect(c.name.length).toBeGreaterThan(1);
      expect(c.visualTraits.length).toBeGreaterThan(5);
      expect(c.accent).toMatch(/^#[0-9A-Fa-f]{6}$/);
    }
  });
});

describe('question fairness', () => {
  it('every question is deterministically answerable for every character', () => {
    for (const q of QUESTIONS) {
      for (const c of CHARACTERS) {
        expect(typeof answerFor(c, q.id)).toBe('boolean');
      }
    }
  });

  it('every question splits the cast meaningfully (never all-yes or all-no)', () => {
    for (const q of QUESTIONS) {
      const yes = CHARACTERS.filter((c) => q.test(c)).length;
      expect(yes, `${q.id} matched ${yes}`).toBeGreaterThan(0);
      expect(yes, `${q.id} matched ${yes}`).toBeLessThan(CHARACTERS.length);
    }
  });

  it('male/female questions partition the cast', () => {
    for (const c of CHARACTERS) {
      expect(answerFor(c, 'q_male')).toBe(!answerFor(c, 'q_female'));
    }
  });

  it('attributes overlap enough for meaningful deduction', () => {
    // No single question should identify a character instantly on average:
    // at least 5 questions must have 4+ positive matches.
    const broad = QUESTIONS.filter((q) => CHARACTERS.filter((c) => q.test(c)).length >= 4);
    expect(broad.length).toBeGreaterThanOrEqual(5);
  });

  it('rejects unknown question ids', () => {
    expect(isValidQuestionId('q_nope')).toBe(false);
    expect(getQuestion('q_nope')).toBeUndefined();
    expect(() => answerFor(CHARACTERS[0], 'q_nope')).toThrow();
  });
});
