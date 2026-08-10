// Production multiplayer backend: Supabase Realtime + authoritative
// PostgreSQL RPCs (see supabase/migrations/0001_init.sql). The opponent's
// secret character never reaches this client: secrets live in game_secrets
// with RLS restricted to the owning player, and games.revealed_secrets is
// populated by the server only after the game is finished.

import { createClient, type RealtimeChannel, type SupabaseClient } from '@supabase/supabase-js';
import { GameError, type GameErrorCode, type PublicGameState, type QuestionLogEntry, type RoomState } from '../game/types';
import type { BackendListeners, GameBackend } from './types';

interface RoomRow {
  id: string;
  code: string;
  status: RoomState['status'];
  host_id: string;
  host_name: string;
  guest_id: string | null;
  guest_name: string | null;
  host_rematch: boolean;
  guest_rematch: boolean;
  current_game_id: string | null;
}

interface GameRow {
  id: string;
  room_id: string;
  status: 'active' | 'finished';
  current_turn: string;
  turn_started_at: string;
  started_at: string;
  finished_at: string | null;
  pending_question_id: string | null;
  pending_asker: string | null;
  host_questions: number;
  guest_questions: number;
  host_score: number;
  guest_score: number;
  winner_id: string | null;
  win_reason: PublicGameState['winReason'];
  last_guess: { playerId: string; characterId: number; correct: boolean } | null;
  revealed_secrets: Record<string, number> | null;
}

interface QuestionRow {
  id: string;
  game_id: string;
  asker_id: string;
  question_id: string;
  answer: boolean | null;
  asked_at: string;
}

const KNOWN_CODES = new Set<GameErrorCode>([
  'ROOM_NOT_FOUND', 'ROOM_FULL', 'ROOM_EXPIRED', 'ROOM_ALREADY_STARTED', 'INVALID_CODE',
  'INVALID_NAME', 'NOT_IN_ROOM', 'GAME_NOT_ACTIVE', 'NOT_YOUR_TURN', 'PENDING_QUESTION',
  'NO_PENDING_QUESTION', 'NOT_DEFENDER', 'INVALID_QUESTION', 'INVALID_CHARACTER',
  'TURN_NOT_EXPIRED', 'REMATCH_NOT_ALLOWED',
]);

function toGameError(err: unknown): GameError {
  const message = (err as { message?: string })?.message ?? '';
  if (KNOWN_CODES.has(message as GameErrorCode)) return new GameError(message as GameErrorCode);
  if (/fetch|network|timeout/i.test(message)) return new GameError('NETWORK', message);
  return new GameError('UNKNOWN', message);
}

export class SupabaseBackend implements GameBackend {
  readonly kind = 'supabase' as const;
  private client: SupabaseClient;
  private playerId = '';
  private listeners: BackendListeners = {};
  private channel: RealtimeChannel | null = null;
  private roomId: string | null = null;
  private gameId: string | null = null;
  private room: RoomRow | null = null;
  private game: GameRow | null = null;
  private questions: QuestionRow[] = [];
  private secretSent: string | null = null;

  constructor(url: string, anonKey: string) {
    this.client = createClient(url, anonKey, {
      auth: { persistSession: true, autoRefreshToken: true },
      realtime: { params: { eventsPerSecond: 10 } },
    });
  }

  async init(): Promise<void> {
    this.listeners.onConnectionChange?.('connecting');
    const { data: { session } } = await this.client.auth.getSession();
    if (session?.user) {
      this.playerId = session.user.id;
    } else {
      const { data, error } = await this.client.auth.signInAnonymously();
      if (error || !data.user) throw new GameError('NETWORK', error?.message);
      this.playerId = data.user.id;
    }
    this.listeners.onConnectionChange?.('connected');
  }

  getPlayerId(): string {
    return this.playerId;
  }

  setListeners(listeners: BackendListeners): void {
    this.listeners = listeners;
  }

  destroy(): void {
    void this.teardownChannel();
  }

  /* ------------------------------ projections ------------------------------ */

  private emitRoom(): void {
    const r = this.room;
    if (!r) return;
    const players: RoomState['players'] = [
      { id: r.host_id, name: r.host_name, seat: 1, online: true, rematchRequested: r.host_rematch },
    ];
    if (r.guest_id) {
      players.push({ id: r.guest_id, name: r.guest_name ?? '', seat: 2, online: true, rematchRequested: r.guest_rematch });
    }
    this.listeners.onRoomUpdate?.({
      id: r.id, code: r.code, status: r.status, players, currentGameId: r.current_game_id,
    });
  }

  private emitGame(): void {
    const g = this.game;
    const r = this.room;
    if (!g || !r || !r.guest_id) return;
    const history: QuestionLogEntry[] = this.questions.map((q) => ({
      id: q.id, askerId: q.asker_id, questionId: q.question_id, answer: q.answer,
      askedAt: Date.parse(q.asked_at),
    }));
    this.listeners.onGameUpdate?.({
      id: g.id,
      roomId: g.room_id,
      status: g.status,
      currentTurnPlayerId: g.current_turn,
      turnStartedAt: Date.parse(g.turn_started_at),
      startedAt: Date.parse(g.started_at),
      finishedAt: g.finished_at ? Date.parse(g.finished_at) : null,
      pendingQuestion: g.pending_question_id && g.pending_asker
        ? { questionId: g.pending_question_id, askerId: g.pending_asker }
        : null,
      questionsUsed: { [r.host_id]: g.host_questions, [r.guest_id]: g.guest_questions },
      scores: { [r.host_id]: g.host_score, [r.guest_id]: g.guest_score },
      history,
      winnerId: g.winner_id,
      winReason: g.win_reason,
      revealedSecrets: g.status === 'finished' ? g.revealed_secrets : null,
      lastGuess: g.last_guess,
    });
  }

  /* ------------------------------ data loading ------------------------------ */

  private async loadRoom(roomId: string): Promise<void> {
    const { data, error } = await this.client.from('rooms').select('*').eq('id', roomId).single();
    if (error) throw toGameError(error);
    this.room = data as RoomRow;
  }

  private async loadGame(gameId: string): Promise<void> {
    const [gameRes, questionsRes] = await Promise.all([
      this.client.from('games').select('*').eq('id', gameId).single(),
      this.client.from('game_questions').select('*').eq('game_id', gameId).order('asked_at'),
    ]);
    if (gameRes.error) throw toGameError(gameRes.error);
    this.game = gameRes.data as GameRow;
    this.questions = (questionsRes.data ?? []) as QuestionRow[];
  }

  private async fetchSecret(gameId: string): Promise<void> {
    if (this.secretSent === gameId) return;
    const { data, error } = await this.client.rpc('get_my_secret', { p_game_id: gameId });
    if (error) throw toGameError(error);
    this.secretSent = gameId;
    this.listeners.onSecret?.(data as number, gameId);
  }

  private async onGameIdChanged(gameId: string | null): Promise<void> {
    this.gameId = gameId;
    if (!gameId) return;
    await this.loadGame(gameId);
    // Emit the game before the secret so the store never interprets the
    // secret as belonging to a stale game (it is also tagged with gameId).
    this.emitGame();
    await this.fetchSecret(gameId);
  }

  /* ------------------------------ realtime ------------------------------ */

  private async setupChannel(roomId: string): Promise<void> {
    await this.teardownChannel();
    this.roomId = roomId;

    const channel = this.client.channel(`room:${roomId}`, {
      config: { presence: { key: this.playerId } },
    });

    channel.on('postgres_changes',
      { event: 'UPDATE', schema: 'public', table: 'rooms', filter: `id=eq.${roomId}` },
      async (payload) => {
        const prevGameId = this.room?.current_game_id ?? null;
        this.room = payload.new as RoomRow;
        this.emitRoom();
        const newGameId = this.room.current_game_id;
        if (newGameId && newGameId !== prevGameId) {
          await this.onGameIdChanged(newGameId);
        }
      });

    channel.on('postgres_changes',
      { event: '*', schema: 'public', table: 'games', filter: `room_id=eq.${roomId}` },
      async (payload) => {
        const row = payload.new as GameRow;
        if (this.gameId && row.id !== this.gameId) return;
        if (!this.gameId) await this.onGameIdChanged(row.id);
        this.game = row;
        this.emitGame();
      });

    channel.on('postgres_changes',
      { event: '*', schema: 'public', table: 'game_questions' },
      (payload) => {
        const row = (payload.new ?? payload.old) as QuestionRow;
        if (!row || row.game_id !== this.gameId) return;
        if (payload.eventType === 'INSERT') {
          if (!this.questions.some((q) => q.id === row.id)) this.questions.push(row);
        } else if (payload.eventType === 'UPDATE') {
          this.questions = this.questions.map((q) => (q.id === row.id ? row : q));
        } else if (payload.eventType === 'DELETE') {
          this.questions = this.questions.filter((q) => q.id !== (payload.old as QuestionRow).id);
        }
        this.emitGame();
      });

    channel.on('presence', { event: 'sync' }, () => {
      const state = channel.presenceState();
      const others = Object.keys(state).filter((k) => k !== this.playerId);
      this.listeners.onOpponentPresence?.(others.length > 0);
    });

    await new Promise<void>((resolve) => {
      channel.subscribe(async (status) => {
        if (status === 'SUBSCRIBED') {
          this.listeners.onConnectionChange?.('connected');
          await channel.track({ online_at: new Date().toISOString() });
          // Re-sync after (re)subscribe so missed events are recovered.
          try {
            await this.loadRoom(roomId);
            this.emitRoom();
            const gid = this.room?.current_game_id ?? null;
            if (gid) await this.onGameIdChanged(gid);
          } catch { /* transient; next event will retry */ }
          resolve();
        } else if (status === 'CHANNEL_ERROR' || status === 'TIMED_OUT') {
          this.listeners.onConnectionChange?.('reconnecting');
        } else if (status === 'CLOSED') {
          resolve();
        }
      });
    });

    this.channel = channel;
  }

  private async teardownChannel(): Promise<void> {
    if (this.channel) {
      await this.client.removeChannel(this.channel);
      this.channel = null;
    }
  }

  /* ------------------------------ room ops ------------------------------ */

  private toRoomState(r: RoomRow): RoomState {
    const players: RoomState['players'] = [
      { id: r.host_id, name: r.host_name, seat: 1, online: true, rematchRequested: r.host_rematch },
    ];
    if (r.guest_id) {
      players.push({ id: r.guest_id, name: r.guest_name ?? '', seat: 2, online: true, rematchRequested: r.guest_rematch });
    }
    return { id: r.id, code: r.code, status: r.status, players, currentGameId: r.current_game_id };
  }

  async createRoom(name: string): Promise<RoomState> {
    const { data, error } = await this.client.rpc('create_room', { p_name: name });
    if (error) throw toGameError(error);
    this.room = data as RoomRow;
    await this.setupChannel(this.room.id);
    return this.toRoomState(this.room);
  }

  async joinRoom(code: string, name: string): Promise<RoomState> {
    const { data, error } = await this.client.rpc('join_room', { p_code: code, p_name: name });
    if (error) throw toGameError(error);
    this.room = data as RoomRow;
    await this.setupChannel(this.room.id);
    return this.toRoomState(this.room);
  }

  async resumeRoom(roomId: string): Promise<RoomState | null> {
    try {
      await this.loadRoom(roomId);
    } catch {
      return null;
    }
    if (!this.room) return null;
    await this.setupChannel(roomId);
    return this.toRoomState(this.room);
  }

  async leaveRoom(): Promise<void> {
    const roomId = this.roomId;
    await this.teardownChannel();
    this.roomId = null;
    this.gameId = null;
    this.game = null;
    this.room = null;
    this.questions = [];
    this.secretSent = null;
    if (roomId) {
      const { error } = await this.client.rpc('leave_room', { p_room_id: roomId });
      if (error && !/NOT_IN_ROOM/.test(error.message)) {
        // Leaving is best-effort; the room expires server-side anyway.
        console.warn('leave_room failed', error.message);
      }
    }
  }

  /* ------------------------------ game ops ------------------------------ */

  private async rpc(fn: string, args: Record<string, unknown>): Promise<void> {
    const { error } = await this.client.rpc(fn, args);
    if (error) throw toGameError(error);
  }

  async askQuestion(questionId: string): Promise<void> {
    if (!this.gameId) throw new GameError('GAME_NOT_ACTIVE');
    await this.rpc('ask_question', { p_game_id: this.gameId, p_question_id: questionId });
  }

  async answerQuestion(answer: boolean): Promise<void> {
    if (!this.gameId) throw new GameError('GAME_NOT_ACTIVE');
    await this.rpc('answer_question', { p_game_id: this.gameId, p_answer: answer });
  }

  async submitGuess(characterId: number): Promise<void> {
    if (!this.gameId) throw new GameError('GAME_NOT_ACTIVE');
    await this.rpc('submit_guess', { p_game_id: this.gameId, p_character_id: characterId });
  }

  async timeoutTurn(): Promise<void> {
    if (!this.gameId) throw new GameError('GAME_NOT_ACTIVE');
    await this.rpc('timeout_turn', { p_game_id: this.gameId });
  }

  async requestRematch(): Promise<void> {
    if (!this.roomId) throw new GameError('ROOM_NOT_FOUND');
    await this.rpc('request_rematch', { p_room_id: this.roomId });
  }
}
