// Development-only backend: simulates the authoritative server inside the
// browser so the game can be played between two tabs of the same browser
// without Supabase credentials. Uses the exact same rule engine
// (src/game/serverLogic.ts) that the tests cover. Production builds with
// Supabase credentials never use this class.

import { GameError, type RoomState, type ServerGameState } from '../game/types';
import {
  generateRoomCode, normalizeRoomCode, isValidRoomCode, sanitizeName, isValidName,
  ROOM_TTL_MINUTES,
} from '../game/logic';
import * as rules from '../game/serverLogic';
import type { BackendListeners, GameBackend } from './types';

interface LocalRoomRecord {
  id: string;
  code: string;
  status: RoomState['status'];
  createdAt: number;
  expiresAt: number;
  players: { id: string; name: string; seat: 1 | 2; rematchRequested: boolean }[];
  currentGameId: string | null;
  games: Record<string, ServerGameState>;
  /** Monotonic revision so tabs can converge on the newest state. */
  rev: number;
}

interface LocalStore {
  rooms: Record<string, LocalRoomRecord>; // keyed by room code
}

const STORE_KEY = 'ana-meno-local-store';
const CHANNEL = 'ana-meno-local';
const PRESENCE_TIMEOUT_MS = 8000;

function loadStore(): LocalStore {
  try {
    const raw = localStorage.getItem(STORE_KEY);
    if (raw) return JSON.parse(raw) as LocalStore;
  } catch { /* corrupted store -> reset */ }
  return { rooms: {} };
}

function saveStore(store: LocalStore): void {
  localStorage.setItem(STORE_KEY, JSON.stringify(store));
}

export class LocalBackend implements GameBackend {
  readonly kind = 'local' as const;
  private playerId: string;
  private roomCode: string | null = null;
  private listeners: BackendListeners = {};
  private channel: BroadcastChannel | null = null;
  private heartbeatTimer: ReturnType<typeof setInterval> | null = null;
  private lastOpponentBeat = 0;
  private opponentOnline = false;

  constructor(playerIdOverride?: string) {
    if (playerIdOverride) {
      this.playerId = playerIdOverride;
      return;
    }
    // sessionStorage is per-tab, so two tabs act as two distinct players.
    let id = sessionStorage.getItem('ana-meno-player-id');
    if (!id) {
      id = `p_${Math.random().toString(36).slice(2, 10)}${Date.now().toString(36)}`;
      sessionStorage.setItem('ana-meno-player-id', id);
    }
    this.playerId = id;
  }

  async init(): Promise<void> {
    this.channel = new BroadcastChannel(CHANNEL);
    this.channel.onmessage = (ev) => this.onMessage(ev.data);
    this.listeners.onConnectionChange?.('connected');
    this.heartbeatTimer = setInterval(() => this.heartbeat(), 2500);
  }

  getPlayerId(): string {
    return this.playerId;
  }

  setListeners(listeners: BackendListeners): void {
    this.listeners = listeners;
  }

  destroy(): void {
    if (this.heartbeatTimer) clearInterval(this.heartbeatTimer);
    this.channel?.close();
    this.channel = null;
  }

  /* ------------------------------ messaging ------------------------------ */

  private onMessage(msg: { type: string; roomCode?: string; playerId?: string; record?: LocalRoomRecord }): void {
    if (msg.type === 'sync' && msg.roomCode === this.roomCode) {
      // localStorage replication between browser processes can lag behind the
      // BroadcastChannel message, so the authoritative record travels in the
      // message itself and is merged in if it is newer than the local copy.
      if (msg.record) {
        const store = loadStore();
        const local = store.rooms[msg.record.code];
        if (!local || (msg.record.rev ?? 0) >= (local.rev ?? 0)) {
          store.rooms[msg.record.code] = msg.record;
          saveStore(store);
        }
      }
      this.emitCurrent();
    }
    if (msg.type === 'beat' && msg.roomCode === this.roomCode && msg.playerId !== this.playerId) {
      this.lastOpponentBeat = Date.now();
      if (!this.opponentOnline) {
        this.opponentOnline = true;
        this.listeners.onOpponentPresence?.(true);
      }
    }
  }

  private heartbeat(): void {
    if (!this.roomCode) return;
    this.channel?.postMessage({ type: 'beat', roomCode: this.roomCode, playerId: this.playerId });
    if (this.opponentOnline && Date.now() - this.lastOpponentBeat > PRESENCE_TIMEOUT_MS) {
      this.opponentOnline = false;
      this.listeners.onOpponentPresence?.(false);
    }
  }

  private broadcastSync(): void {
    const rec = this.currentRecord();
    this.channel?.postMessage({ type: 'sync', roomCode: this.roomCode, record: rec ?? undefined });
  }

  /* ------------------------------ projections ------------------------------ */

  private toRoomState(rec: LocalRoomRecord): RoomState {
    return {
      id: rec.id,
      code: rec.code,
      status: rec.status,
      players: rec.players.map((p) => ({ ...p, online: true })),
      currentGameId: rec.currentGameId,
    };
  }

  private emitCurrent(): void {
    const rec = this.currentRecord();
    if (!rec) return;
    this.listeners.onRoomUpdate?.(this.toRoomState(rec));
    if (rec.currentGameId) {
      const game = rec.games[rec.currentGameId];
      if (game) {
        this.listeners.onGameUpdate?.(rules.publicStateFor(game));
        if (game.secrets[this.playerId] != null) {
          this.listeners.onSecret?.(game.secrets[this.playerId]);
        }
      }
    }
  }

  private currentRecord(): LocalRoomRecord | null {
    if (!this.roomCode) return null;
    return loadStore().rooms[this.roomCode] ?? null;
  }

  /* ------------------------------ room ops ------------------------------ */

  async createRoom(nameInput: string): Promise<RoomState> {
    const name = sanitizeName(nameInput);
    if (!isValidName(name)) throw new GameError('INVALID_NAME');
    const store = loadStore();
    let code = generateRoomCode();
    while (store.rooms[code]) code = generateRoomCode();
    const rec: LocalRoomRecord = {
      id: `room_${code}`,
      code,
      status: 'waiting',
      createdAt: Date.now(),
      expiresAt: Date.now() + ROOM_TTL_MINUTES * 60_000,
      players: [{ id: this.playerId, name, seat: 1, rematchRequested: false }],
      currentGameId: null,
      games: {},
      rev: 1,
    };
    store.rooms[code] = rec;
    saveStore(store);
    this.roomCode = code;
    this.broadcastSync();
    queueMicrotask(() => this.emitCurrent());
    return this.toRoomState(rec);
  }

  async joinRoom(codeInput: string, nameInput: string): Promise<RoomState> {
    const code = normalizeRoomCode(codeInput);
    if (!isValidRoomCode(code)) throw new GameError('INVALID_CODE');
    const name = sanitizeName(nameInput);
    if (!isValidName(name)) throw new GameError('INVALID_NAME');

    const store = loadStore();
    const rec = store.rooms[code];
    if (!rec) throw new GameError('ROOM_NOT_FOUND');
    if (Date.now() > rec.expiresAt && rec.status === 'waiting') throw new GameError('ROOM_EXPIRED');
    if (rec.players.some((p) => p.id === this.playerId)) {
      this.roomCode = code;
      queueMicrotask(() => this.emitCurrent());
      return this.toRoomState(rec);
    }
    if (rec.status !== 'waiting') throw new GameError('ROOM_ALREADY_STARTED');
    if (rec.players.length >= 2) throw new GameError('ROOM_FULL');

    rec.players.push({ id: this.playerId, name, seat: 2, rematchRequested: false });
    // Second player joined -> the "server" generates the game.
    const game = rules.createGame(rec.id, [rec.players[0].id, rec.players[1].id]);
    rec.games[game.id] = game;
    rec.currentGameId = game.id;
    rec.status = 'playing';
    rec.rev = (rec.rev ?? 0) + 1;
    saveStore(store);
    this.roomCode = code;
    this.broadcastSync();
    queueMicrotask(() => this.emitCurrent());
    return this.toRoomState(rec);
  }

  async resumeRoom(roomId: string): Promise<RoomState | null> {
    const store = loadStore();
    const rec = Object.values(store.rooms).find((r) => r.id === roomId);
    if (!rec || !rec.players.some((p) => p.id === this.playerId)) return null;
    this.roomCode = rec.code;
    queueMicrotask(() => this.emitCurrent());
    return this.toRoomState(rec);
  }

  async leaveRoom(): Promise<void> {
    const store = loadStore();
    const rec = this.roomCode ? store.rooms[this.roomCode] : null;
    if (rec) {
      const gameId = rec.currentGameId;
      const game = gameId ? rec.games[gameId] : null;
      if (game && game.status === 'active') {
        rec.games[gameId!] = rules.forfeit(game, this.playerId);
      }
      rec.status = 'finished';
      rec.rev = (rec.rev ?? 0) + 1;
      saveStore(store);
      this.broadcastSync();
    }
    this.roomCode = null;
  }

  /* ------------------------------ game ops ------------------------------ */

  private mutateGame(fn: (game: ServerGameState) => ServerGameState): void {
    const store = loadStore();
    const rec = this.roomCode ? store.rooms[this.roomCode] : null;
    if (!rec || !rec.currentGameId) throw new GameError('GAME_NOT_ACTIVE');
    const game = rec.games[rec.currentGameId];
    if (!game) throw new GameError('GAME_NOT_ACTIVE');
    rec.games[rec.currentGameId] = fn(game);
    if (rec.games[rec.currentGameId].status === 'finished') rec.status = 'finished';
    rec.rev = (rec.rev ?? 0) + 1;
    saveStore(store);
    this.broadcastSync();
    this.emitCurrent();
  }

  async askQuestion(questionId: string): Promise<void> {
    this.mutateGame((g) => rules.askQuestion(g, this.playerId, questionId));
  }

  async answerQuestion(answer: boolean): Promise<void> {
    this.mutateGame((g) => rules.answerQuestion(g, this.playerId, answer));
  }

  async submitGuess(characterId: number): Promise<void> {
    this.mutateGame((g) => rules.submitGuess(g, this.playerId, characterId));
  }

  async timeoutTurn(): Promise<void> {
    this.mutateGame((g) => rules.timeoutTurn(g, this.playerId));
  }

  async requestRematch(): Promise<void> {
    const store = loadStore();
    const rec = this.roomCode ? store.rooms[this.roomCode] : null;
    if (!rec) throw new GameError('ROOM_NOT_FOUND');
    if (rec.players.length !== 2) throw new GameError('REMATCH_NOT_ALLOWED');
    const game = rec.currentGameId ? rec.games[rec.currentGameId] : null;
    if (!game || game.status !== 'finished') throw new GameError('REMATCH_NOT_ALLOWED');

    const me = rec.players.find((p) => p.id === this.playerId);
    if (!me) throw new GameError('NOT_IN_ROOM');
    me.rematchRequested = true;

    if (rec.players.every((p) => p.rematchRequested)) {
      const fresh = rules.createGame(rec.id, [rec.players[0].id, rec.players[1].id]);
      rec.games[fresh.id] = fresh;
      rec.currentGameId = fresh.id;
      rec.status = 'playing';
      for (const p of rec.players) p.rematchRequested = false;
    }
    rec.rev = (rec.rev ?? 0) + 1;
    saveStore(store);
    this.broadcastSync();
    this.emitCurrent();
  }
}
