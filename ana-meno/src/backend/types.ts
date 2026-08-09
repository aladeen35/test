import type { PublicGameState, RoomState } from '../game/types';

export type ConnectionStatus = 'connected' | 'connecting' | 'reconnecting' | 'offline';

export interface BackendListeners {
  onRoomUpdate?: (room: RoomState) => void;
  onGameUpdate?: (game: PublicGameState) => void;
  onSecret?: (characterId: number) => void;
  onConnectionChange?: (status: ConnectionStatus) => void;
  onOpponentPresence?: (online: boolean) => void;
}

/**
 * Abstraction over the multiplayer backend. Production uses Supabase
 * (SupabaseBackend); local development without credentials uses
 * LocalBackend (BroadcastChannel between two tabs of the same browser).
 * All game-rule validation happens on the authoritative side, never in UI.
 */
export interface GameBackend {
  readonly kind: 'supabase' | 'local';
  /** Resolves once the backend has an identity (anonymous auth). */
  init(): Promise<void>;
  getPlayerId(): string;

  createRoom(name: string): Promise<RoomState>;
  joinRoom(code: string, name: string): Promise<RoomState>;
  /** Re-attach to a room after reload/reconnect. */
  resumeRoom(roomId: string): Promise<RoomState | null>;
  leaveRoom(): Promise<void>;

  askQuestion(questionId: string): Promise<void>;
  answerQuestion(answer: boolean): Promise<void>;
  submitGuess(characterId: number): Promise<void>;
  timeoutTurn(): Promise<void>;
  requestRematch(): Promise<void>;

  setListeners(listeners: BackendListeners): void;
  destroy(): void;
}
