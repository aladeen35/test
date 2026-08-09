// Core domain types shared by game logic, backends and UI.

export type Gender = 'male' | 'female';
export type SkinTone = 'light' | 'tan' | 'medium' | 'dark';
export type HairColor = 'black' | 'brown' | 'gray' | 'blonde' | 'covered';
export type HairLength = 'short' | 'long' | 'none' | 'covered';
export type BeardStyle = 'none' | 'trimmed' | 'full';

export interface Character {
  id: number;
  slug: string;
  name: string;
  gender: Gender;
  profession: string;
  professionAr: string;
  field: string;
  skinTone: SkinTone;
  hairColor: HairColor;
  hairLength: HairLength;
  hairStyle: string;
  hasGlasses: boolean;
  beardStyle: BeardStyle;
  headwear: string;
  clothing: string;
  uniform: boolean;
  accessory: string;
  worksInOffice: boolean;
  worksOutdoors: boolean;
  accent: string;
  visualTraits: string;
}

export type QuestionCategoryId =
  | 'appearance'
  | 'profession'
  | 'clothing'
  | 'accessories'
  | 'traits';

export interface Question {
  id: string;
  category: QuestionCategoryId;
  textAr: string;
  test: (c: Character) => boolean;
}

export type RoomStatus = 'waiting' | 'playing' | 'finished' | 'expired';
export type GameStatus = 'active' | 'finished';
export type WinReason = 'correct_guess' | 'opponent_wrong_guess' | 'forfeit' | null;

export interface RoomPlayer {
  id: string;
  name: string;
  seat: 1 | 2;
  online: boolean;
  rematchRequested: boolean;
}

export interface RoomState {
  id: string;
  code: string;
  status: RoomStatus;
  players: RoomPlayer[];
  currentGameId: string | null;
}

export interface QuestionLogEntry {
  id: string;
  askerId: string;
  questionId: string;
  answer: boolean | null;
  askedAt: number;
}

export interface PendingQuestion {
  questionId: string;
  askerId: string;
}

/** The game state that is safe to send to any player (no secrets). */
export interface PublicGameState {
  id: string;
  roomId: string;
  status: GameStatus;
  currentTurnPlayerId: string;
  turnStartedAt: number;
  startedAt: number;
  finishedAt: number | null;
  pendingQuestion: PendingQuestion | null;
  questionsUsed: Record<string, number>;
  scores: Record<string, number>;
  history: QuestionLogEntry[];
  winnerId: string | null;
  winReason: WinReason;
  /** Only populated once the game is finished. */
  revealedSecrets: Record<string, number> | null;
  lastGuess: { playerId: string; characterId: number; correct: boolean } | null;
}

/** Server-side game state; `secrets` must never reach the opposing client. */
export interface ServerGameState extends Omit<PublicGameState, 'revealedSecrets'> {
  secrets: Record<string, number>;
}

export type GameErrorCode =
  | 'ROOM_NOT_FOUND'
  | 'ROOM_FULL'
  | 'ROOM_EXPIRED'
  | 'ROOM_ALREADY_STARTED'
  | 'INVALID_CODE'
  | 'INVALID_NAME'
  | 'NOT_IN_ROOM'
  | 'GAME_NOT_ACTIVE'
  | 'NOT_YOUR_TURN'
  | 'PENDING_QUESTION'
  | 'NO_PENDING_QUESTION'
  | 'NOT_DEFENDER'
  | 'INVALID_QUESTION'
  | 'INVALID_CHARACTER'
  | 'TURN_NOT_EXPIRED'
  | 'REMATCH_NOT_ALLOWED'
  | 'NETWORK'
  | 'UNKNOWN';

export class GameError extends Error {
  code: GameErrorCode;
  constructor(code: GameErrorCode, message?: string) {
    super(message ?? code);
    this.code = code;
    this.name = 'GameError';
  }
}
