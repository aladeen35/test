// Authoritative game state machine. This module is the single source of
// truth for game rules. It is used directly by the local development
// backend and by the test suite; the Supabase SQL functions implement the
// same transitions server-side (see supabase/migrations/0001_init.sql).

import { GameError, type PublicGameState, type ServerGameState } from './types';
import { isValidQuestionId } from './questions';
import { computeScore, pickSecretCharacters, TURN_SECONDS, type RandomInt, cryptoRandomInt } from './logic';
import { CHARACTERS } from './characters';

let counter = 0;
function makeId(prefix: string): string {
  counter += 1;
  return `${prefix}_${Date.now().toString(36)}_${counter.toString(36)}`;
}

export function createGame(
  roomId: string,
  playerIds: [string, string],
  now: number = Date.now(),
  rand: RandomInt = cryptoRandomInt,
): ServerGameState {
  const [p1, p2] = playerIds;
  if (!p1 || !p2 || p1 === p2) throw new GameError('ROOM_NOT_FOUND', 'Two distinct players required');
  const [s1, s2] = pickSecretCharacters(CHARACTERS.map((c) => c.id), rand);
  return {
    id: makeId('game'),
    roomId,
    status: 'active',
    currentTurnPlayerId: p1,
    turnStartedAt: now,
    startedAt: now,
    finishedAt: null,
    pendingQuestion: null,
    questionsUsed: { [p1]: 0, [p2]: 0 },
    scores: { [p1]: 0, [p2]: 0 },
    history: [],
    winnerId: null,
    winReason: null,
    lastGuess: null,
    secrets: { [p1]: s1, [p2]: s2 },
  };
}

function playerIds(game: ServerGameState): string[] {
  return Object.keys(game.secrets);
}

export function opponentOf(game: ServerGameState, playerId: string): string {
  const other = playerIds(game).find((id) => id !== playerId);
  if (!other) throw new GameError('NOT_IN_ROOM');
  return other;
}

function assertPlayer(game: ServerGameState, playerId: string): void {
  if (!playerIds(game).includes(playerId)) throw new GameError('NOT_IN_ROOM');
}

function assertActive(game: ServerGameState): void {
  if (game.status !== 'active') throw new GameError('GAME_NOT_ACTIVE');
}

export function askQuestion(
  game: ServerGameState,
  playerId: string,
  questionId: string,
  now: number = Date.now(),
): ServerGameState {
  assertPlayer(game, playerId);
  assertActive(game);
  if (game.currentTurnPlayerId !== playerId) throw new GameError('NOT_YOUR_TURN');
  if (game.pendingQuestion) throw new GameError('PENDING_QUESTION');
  if (!isValidQuestionId(questionId)) throw new GameError('INVALID_QUESTION');

  return {
    ...game,
    pendingQuestion: { questionId, askerId: playerId },
    questionsUsed: { ...game.questionsUsed, [playerId]: game.questionsUsed[playerId] + 1 },
    history: [
      ...game.history,
      { id: makeId('q'), askerId: playerId, questionId, answer: null, askedAt: now },
    ],
  };
}

export function answerQuestion(
  game: ServerGameState,
  playerId: string,
  answer: boolean,
  now: number = Date.now(),
): ServerGameState {
  assertPlayer(game, playerId);
  assertActive(game);
  if (!game.pendingQuestion) throw new GameError('NO_PENDING_QUESTION');
  // Only the defender (the player who is NOT the asker) may answer.
  if (game.pendingQuestion.askerId === playerId) throw new GameError('NOT_DEFENDER');

  const history = [...game.history];
  const last = history[history.length - 1];
  history[history.length - 1] = { ...last, answer };

  // After the answer, the turn passes to the defender.
  return {
    ...game,
    pendingQuestion: null,
    history,
    currentTurnPlayerId: playerId,
    turnStartedAt: now,
  };
}

export function submitGuess(
  game: ServerGameState,
  playerId: string,
  characterId: number,
  now: number = Date.now(),
): ServerGameState {
  assertPlayer(game, playerId);
  assertActive(game);
  if (game.currentTurnPlayerId !== playerId) throw new GameError('NOT_YOUR_TURN');
  if (game.pendingQuestion) throw new GameError('PENDING_QUESTION');
  if (!CHARACTERS.some((c) => c.id === characterId)) throw new GameError('INVALID_CHARACTER');

  const opponent = opponentOf(game, playerId);
  const correct = game.secrets[opponent] === characterId;
  const winnerId = correct ? playerId : opponent;
  const elapsedSeconds = (now - game.startedAt) / 1000;
  const winnerScore = computeScore(game.questionsUsed[winnerId], elapsedSeconds).total;

  return {
    ...game,
    status: 'finished',
    finishedAt: now,
    winnerId,
    winReason: correct ? 'correct_guess' : 'opponent_wrong_guess',
    lastGuess: { playerId, characterId, correct },
    scores: { ...game.scores, [winnerId]: winnerScore },
  };
}

/**
 * Either player may report an expired turn; validated against the clock so a
 * malicious client cannot skip the opponent's turn early.
 */
export function timeoutTurn(
  game: ServerGameState,
  playerId: string,
  now: number = Date.now(),
): ServerGameState {
  assertPlayer(game, playerId);
  assertActive(game);
  if (now - game.turnStartedAt < TURN_SECONDS * 1000) throw new GameError('TURN_NOT_EXPIRED');

  const next = opponentOf(game, game.currentTurnPlayerId);
  const history = [...game.history];
  const questionsUsed = { ...game.questionsUsed };
  if (game.pendingQuestion) {
    // The defender never answered: drop the question from the log and
    // refund it to the asker so they are not penalized.
    history.pop();
    const asker = game.pendingQuestion.askerId;
    questionsUsed[asker] = Math.max(0, questionsUsed[asker] - 1);
  }
  return {
    ...game,
    pendingQuestion: null,
    history,
    questionsUsed,
    currentTurnPlayerId: next,
    turnStartedAt: now,
  };
}

export function forfeit(
  game: ServerGameState,
  leavingPlayerId: string,
  now: number = Date.now(),
): ServerGameState {
  assertPlayer(game, leavingPlayerId);
  if (game.status !== 'active') return game;
  const winnerId = opponentOf(game, leavingPlayerId);
  const winnerScore = computeScore(game.questionsUsed[winnerId], (now - game.startedAt) / 1000).total;
  return {
    ...game,
    status: 'finished',
    finishedAt: now,
    winnerId,
    winReason: 'forfeit',
    scores: { ...game.scores, [winnerId]: winnerScore },
  };
}

/** Projection for one player: never leaks the opponent's secret while active. */
export function publicStateFor(game: ServerGameState): PublicGameState {
  const { secrets, ...rest } = game;
  return {
    ...rest,
    revealedSecrets: game.status === 'finished' ? { ...secrets } : null,
  };
}

export function secretFor(game: ServerGameState, playerId: string): number {
  assertPlayer(game, playerId);
  return game.secrets[playerId];
}
