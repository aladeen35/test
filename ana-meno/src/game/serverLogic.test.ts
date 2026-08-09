import { describe, expect, it } from 'vitest';
import {
  answerQuestion, askQuestion, createGame, forfeit, publicStateFor, secretFor, submitGuess,
  timeoutTurn,
} from './serverLogic';
import { GameError } from './types';
import { TURN_SECONDS } from './logic';

const P1 = 'player-1';
const P2 = 'player-2';
const T0 = 1_700_000_000_000;

function freshGame() {
  return createGame('room-1', [P1, P2], T0);
}

describe('createGame', () => {
  it('assigns two different secret characters', () => {
    for (let i = 0; i < 300; i++) {
      const g = freshGame();
      expect(g.secrets[P1]).not.toBe(g.secrets[P2]);
      expect(g.secrets[P1]).toBeGreaterThanOrEqual(1);
      expect(g.secrets[P2]).toBeLessThanOrEqual(30);
    }
  });

  it('starts with player 1 turn and zero questions', () => {
    const g = freshGame();
    expect(g.currentTurnPlayerId).toBe(P1);
    expect(g.questionsUsed).toEqual({ [P1]: 0, [P2]: 0 });
    expect(g.status).toBe('active');
  });

  it('rejects identical or missing players', () => {
    expect(() => createGame('r', [P1, P1])).toThrow(GameError);
  });
});

describe('question flow and turn validation', () => {
  it('rejects a question out of turn', () => {
    const g = freshGame();
    expect(() => askQuestion(g, P2, 'q_male')).toThrowError(/NOT_YOUR_TURN/);
  });

  it('rejects unknown players', () => {
    const g = freshGame();
    expect(() => askQuestion(g, 'intruder', 'q_male')).toThrowError(/NOT_IN_ROOM/);
  });

  it('rejects invalid question ids', () => {
    const g = freshGame();
    expect(() => askQuestion(g, P1, 'q_bogus')).toThrowError(/INVALID_QUESTION/);
  });

  it('rejects a second question while one is pending', () => {
    const g = askQuestion(freshGame(), P1, 'q_male');
    expect(() => askQuestion(g, P1, 'q_glasses')).toThrowError(/PENDING_QUESTION/);
  });

  it('counts questions per player', () => {
    const g = askQuestion(freshGame(), P1, 'q_male');
    expect(g.questionsUsed[P1]).toBe(1);
    expect(g.questionsUsed[P2]).toBe(0);
    expect(g.pendingQuestion).toEqual({ questionId: 'q_male', askerId: P1 });
  });

  it('only the defender may answer', () => {
    const g = askQuestion(freshGame(), P1, 'q_male');
    expect(() => answerQuestion(g, P1, true)).toThrowError(/NOT_DEFENDER/);
  });

  it('rejects answering when nothing is pending', () => {
    expect(() => answerQuestion(freshGame(), P2, true)).toThrowError(/NO_PENDING_QUESTION/);
  });

  it('answering records the answer and passes the turn to the defender', () => {
    let g = askQuestion(freshGame(), P1, 'q_male', T0 + 1000);
    g = answerQuestion(g, P2, true, T0 + 5000);
    expect(g.pendingQuestion).toBeNull();
    expect(g.history).toHaveLength(1);
    expect(g.history[0].answer).toBe(true);
    expect(g.currentTurnPlayerId).toBe(P2);
    expect(g.turnStartedAt).toBe(T0 + 5000);
  });

  it('supports alternating turns', () => {
    let g = freshGame();
    g = askQuestion(g, P1, 'q_male');
    g = answerQuestion(g, P2, false);
    g = askQuestion(g, P2, 'q_glasses');
    g = answerQuestion(g, P1, true);
    expect(g.currentTurnPlayerId).toBe(P1);
    expect(g.history.map((h) => h.answer)).toEqual([false, true]);
  });
});

describe('guessing', () => {
  it('rejects guesses out of turn', () => {
    const g = freshGame();
    expect(() => submitGuess(g, P2, 3)).toThrowError(/NOT_YOUR_TURN/);
  });

  it('rejects guesses while a question is pending', () => {
    const g = askQuestion(freshGame(), P1, 'q_male');
    expect(() => submitGuess(g, P1, 3)).toThrowError(/PENDING_QUESTION/);
  });

  it('rejects non-existent characters', () => {
    const g = freshGame();
    expect(() => submitGuess(g, P1, 999)).toThrowError(/INVALID_CHARACTER/);
  });

  it('a correct guess wins and scores the winner', () => {
    const g = freshGame();
    const done = submitGuess(g, P1, g.secrets[P2], T0 + 30_000);
    expect(done.status).toBe('finished');
    expect(done.winnerId).toBe(P1);
    expect(done.winReason).toBe('correct_guess');
    expect(done.lastGuess).toEqual({ playerId: P1, characterId: g.secrets[P2], correct: true });
    // 0 questions, 30s elapsed -> 100 + (50 - 2) = 148
    expect(done.scores[P1]).toBe(148);
    expect(done.scores[P2]).toBe(0);
  });

  it('a wrong guess makes the opponent win', () => {
    const g = freshGame();
    const wrongId = g.secrets[P2] === 1 ? 2 : 1;
    const done = submitGuess(g, P1, wrongId === g.secrets[P2] ? 3 : wrongId, T0 + 10_000);
    expect(done.status).toBe('finished');
    expect(done.winnerId).toBe(P2);
    expect(done.winReason).toBe('opponent_wrong_guess');
    expect(done.scores[P2]).toBeGreaterThan(0);
  });

  it('no moves are allowed after the game finishes', () => {
    const g = freshGame();
    const done = submitGuess(g, P1, g.secrets[P2]);
    expect(() => askQuestion(done, P2, 'q_male')).toThrowError(/GAME_NOT_ACTIVE/);
    expect(() => submitGuess(done, P2, 1)).toThrowError(/GAME_NOT_ACTIVE/);
  });
});

describe('turn timeout', () => {
  it('rejects premature timeout reports', () => {
    const g = freshGame();
    expect(() => timeoutTurn(g, P2, T0 + (TURN_SECONDS - 1) * 1000)).toThrowError(/TURN_NOT_EXPIRED/);
  });

  it('passes the turn after expiry', () => {
    const g = freshGame();
    const after = timeoutTurn(g, P2, T0 + TURN_SECONDS * 1000 + 1);
    expect(after.currentTurnPlayerId).toBe(P2);
  });

  it('drops and refunds an unanswered pending question', () => {
    let g = askQuestion(freshGame(), P1, 'q_male', T0 + 1000);
    g = timeoutTurn(g, P1, T0 + TURN_SECONDS * 1000 + 1);
    expect(g.pendingQuestion).toBeNull();
    expect(g.history).toHaveLength(0);
    expect(g.questionsUsed[P1]).toBe(0);
    expect(g.currentTurnPlayerId).toBe(P2);
  });
});

describe('forfeit / disconnect handling', () => {
  it('leaving an active game hands the win to the opponent', () => {
    const g = freshGame();
    const done = forfeit(g, P1, T0 + 20_000);
    expect(done.status).toBe('finished');
    expect(done.winnerId).toBe(P2);
    expect(done.winReason).toBe('forfeit');
  });

  it('is a no-op on finished games', () => {
    const g = freshGame();
    const done = submitGuess(g, P1, g.secrets[P2]);
    expect(forfeit(done, P2)).toBe(done);
  });
});

describe('secret privacy', () => {
  it('public projection never contains secrets while active', () => {
    const g = freshGame();
    const pub = publicStateFor(g) as unknown as Record<string, unknown>;
    expect(pub.secrets).toBeUndefined();
    expect(pub.revealedSecrets).toBeNull();
    expect(JSON.stringify(pub)).not.toContain('"secrets"');
  });

  it('secrets are revealed only after the game finishes', () => {
    const g = freshGame();
    const done = submitGuess(g, P1, g.secrets[P2]);
    const pub = publicStateFor(done);
    expect(pub.revealedSecrets).toEqual(done.secrets);
  });

  it('secretFor returns only the requesting player’s own secret', () => {
    const g = freshGame();
    expect(secretFor(g, P1)).toBe(g.secrets[P1]);
    expect(() => secretFor(g, 'intruder')).toThrowError(/NOT_IN_ROOM/);
  });
});
