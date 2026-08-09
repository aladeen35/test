// End-to-end flow tests against the development backend, which runs the
// same authoritative rule engine (serverLogic) that Supabase mirrors in SQL.
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { LocalBackend } from './localBackend';
import type { PublicGameState, RoomState } from '../game/types';

/* ------------------------- browser API stubs ------------------------- */

class MemoryStorage implements Storage {
  private map = new Map<string, string>();
  get length() { return this.map.size; }
  clear() { this.map.clear(); }
  getItem(k: string) { return this.map.get(k) ?? null; }
  key(i: number) { return [...this.map.keys()][i] ?? null; }
  removeItem(k: string) { this.map.delete(k); }
  setItem(k: string, v: string) { this.map.set(k, String(v)); }
}

const channels = new Set<FakeBroadcastChannel>();
class FakeBroadcastChannel {
  onmessage: ((ev: { data: unknown }) => void) | null = null;
  constructor(public name: string) { channels.add(this); }
  postMessage(data: unknown) {
    for (const ch of channels) {
      if (ch !== this && ch.name === this.name) {
        ch.onmessage?.({ data });
      }
    }
  }
  close() { channels.delete(this); }
}

beforeEach(() => {
  vi.stubGlobal('localStorage', new MemoryStorage());
  vi.stubGlobal('sessionStorage', new MemoryStorage());
  vi.stubGlobal('BroadcastChannel', FakeBroadcastChannel);
  channels.clear();
});

async function pair() {
  const a = new LocalBackend('player-a');
  const b = new LocalBackend('player-b');
  await a.init();
  await b.init();
  return { a, b };
}

const flush = () => new Promise<void>((r) => setTimeout(r, 0));

interface Captured {
  room: RoomState | null;
  game: PublicGameState | null;
  secret: number | null;
}

function capture(backend: LocalBackend): Captured {
  const c: Captured = { room: null, game: null, secret: null };
  backend.setListeners({
    onRoomUpdate: (room) => { c.room = room; },
    onGameUpdate: (game) => { c.game = game; },
    onSecret: (id) => { c.secret = id; },
  });
  return c;
}

/* -------------------------------- tests -------------------------------- */

describe('room creation and joining', () => {
  it('creates a room with a code and one seat filled', async () => {
    const { a } = await pair();
    const room = await a.createRoom('علاء الدين');
    expect(room.code).toMatch(/^[A-Z2-9]{5}$/);
    expect(room.status).toBe('waiting');
    expect(room.players).toHaveLength(1);
    expect(room.players[0].name).toBe('علاء الدين');
  });

  it('rejects invalid names', async () => {
    const { a } = await pair();
    await expect(a.createRoom('  ')).rejects.toThrowError(/INVALID_NAME/);
  });

  it('rejects joining with an invalid code format', async () => {
    const { b } = await pair();
    await expect(b.joinRoom('ZZ', 'ريم')).rejects.toThrowError(/INVALID_CODE/);
  });

  it('rejects joining a non-existent room', async () => {
    const { b } = await pair();
    await expect(b.joinRoom('ABCDE', 'ريم')).rejects.toThrowError(/ROOM_NOT_FOUND/);
  });

  it('room codes are case-insensitive', async () => {
    const { a, b } = await pair();
    const room = await a.createRoom('علاء');
    const joined = await b.joinRoom(room.code.toLowerCase(), 'ريم');
    expect(joined.players).toHaveLength(2);
  });

  it('enforces the two-player limit', async () => {
    const { a, b } = await pair();
    const c = new LocalBackend('player-c');
    await c.init();
    const room = await a.createRoom('علاء');
    await b.joinRoom(room.code, 'ريم');
    await expect(c.joinRoom(room.code, 'دانا')).rejects.toThrowError(/ROOM_FULL|ROOM_ALREADY_STARTED/);
  });

  it('rejects expired rooms', async () => {
    vi.useFakeTimers();
    try {
      const { a, b } = await pair();
      const room = await a.createRoom('علاء');
      vi.setSystemTime(Date.now() + 61 * 60_000);
      await expect(b.joinRoom(room.code, 'ريم')).rejects.toThrowError(/ROOM_EXPIRED/);
    } finally {
      vi.useRealTimers();
    }
  });
});

describe('game start', () => {
  it('starts the game when the second player joins, with distinct private secrets', async () => {
    const { a, b } = await pair();
    const ca = capture(a);
    const cb = capture(b);
    const room = await a.createRoom('علاء');
    await b.joinRoom(room.code, 'ريم');
    await flush();

    expect(ca.room?.status).toBe('playing');
    expect(cb.room?.status).toBe('playing');
    expect(ca.game?.status).toBe('active');
    expect(ca.game?.id).toBe(cb.game?.id);

    // Distinct secrets, delivered privately.
    expect(ca.secret).not.toBeNull();
    expect(cb.secret).not.toBeNull();
    expect(ca.secret).not.toBe(cb.secret);

    // The public game state carries no secrets while active.
    expect(JSON.stringify(ca.game)).not.toContain('secrets"');
    expect(ca.game?.revealedSecrets).toBeNull();
  });
});

describe('full match flow', () => {
  it('question/answer round-trip, guess, result and rematch', async () => {
    const { a, b } = await pair();
    const ca = capture(a);
    const cb = capture(b);
    const room = await a.createRoom('علاء');
    await b.joinRoom(room.code, 'ريم');
    await flush();

    // Host (player-a) asks; guest receives it instantly.
    await a.askQuestion('q_glasses');
    await flush();
    expect(cb.game?.pendingQuestion?.questionId).toBe('q_glasses');

    // Guest answers; asker receives the answer and turn flips to guest.
    await b.answerQuestion(true);
    await flush();
    expect(ca.game?.history[0].answer).toBe(true);
    expect(ca.game?.currentTurnPlayerId).toBe('player-b');

    // Out-of-turn ask must be rejected by the authority.
    await expect(a.askQuestion('q_male')).rejects.toThrowError(/NOT_YOUR_TURN/);

    // Guest asks; host answers.
    await b.askQuestion('q_beard');
    await expect(b.answerQuestion(true)).rejects.toThrowError(/NOT_DEFENDER/);
    await a.answerQuestion(false);
    await flush();
    expect(cb.game?.history).toHaveLength(2);
    expect(ca.game?.currentTurnPlayerId).toBe('player-a');

    // Host guesses the guest's secret correctly -> host wins on both clients.
    await a.submitGuess(cb.secret!);
    await flush();
    expect(ca.game?.status).toBe('finished');
    expect(cb.game?.status).toBe('finished');
    expect(ca.game?.winnerId).toBe('player-a');
    expect(ca.game?.winnerId).toBe(cb.game?.winnerId);
    expect(ca.game?.scores['player-a']).toBeGreaterThan(0);
    expect(ca.game?.scores['player-a']).toBe(cb.game?.scores['player-a']);
    expect(ca.game?.revealedSecrets).toEqual(cb.game?.revealedSecrets);

    // Rematch: both must agree; then a fresh game starts.
    const firstGameId = ca.game!.id;
    await a.requestRematch();
    await flush();
    expect(ca.game?.id).toBe(firstGameId); // not yet
    await b.requestRematch();
    await flush();
    expect(ca.game?.id).not.toBe(firstGameId);
    expect(ca.game?.status).toBe('active');
    expect(ca.game?.questionsUsed['player-a']).toBe(0);
    expect(ca.game?.history).toHaveLength(0);
    expect(ca.secret).not.toBe(cb.secret);
  });

  it('a wrong guess loses immediately', async () => {
    const { a, b } = await pair();
    const cb = capture(b);
    const room = await a.createRoom('علاء');
    await b.joinRoom(room.code, 'ريم');
    await flush();

    const wrong = cb.secret === 1 ? 2 : 1;
    await a.submitGuess(wrong);
    await flush();
    expect(cb.game?.status).toBe('finished');
    expect(cb.game?.winnerId).toBe('player-b');
    expect(cb.game?.winReason).toBe('opponent_wrong_guess');
  });

  it('guessing a non-existent character is rejected', async () => {
    const { a, b } = await pair();
    const room = await a.createRoom('علاء');
    await b.joinRoom(room.code, 'ريم');
    await flush();
    await expect(a.submitGuess(999)).rejects.toThrowError(/INVALID_CHARACTER/);
  });

  it('leaving an active game forfeits it to the opponent', async () => {
    const { a, b } = await pair();
    const cb = capture(b);
    const room = await a.createRoom('علاء');
    await b.joinRoom(room.code, 'ريم');
    await flush();

    await a.leaveRoom();
    await flush();
    expect(cb.game?.status).toBe('finished');
    expect(cb.game?.winnerId).toBe('player-b');
    expect(cb.game?.winReason).toBe('forfeit');
  });

  it('reconnect: resumeRoom restores room and game state', async () => {
    const { a, b } = await pair();
    const room = await a.createRoom('علاء');
    await b.joinRoom(room.code, 'ريم');
    await flush();

    // Simulate a reload of player a's tab.
    a.destroy();
    const a2 = new LocalBackend('player-a');
    await a2.init();
    const ca2 = capture(a2);
    const resumed = await a2.resumeRoom(room.id);
    await flush();
    expect(resumed?.id).toBe(room.id);
    expect(ca2.game?.status).toBe('active');
    expect(ca2.secret).not.toBeNull();
  });
});
