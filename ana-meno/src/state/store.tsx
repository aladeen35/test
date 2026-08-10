/* eslint-disable react-refresh/only-export-components */
// App-level state: separates UI state (screen, modals), game state (room,
// game, secret, eliminations), network state (connection, presence) and
// audio state (audioManager). Backend events flow in through a reducer.

import {
  createContext, useCallback, useContext, useEffect, useMemo, useReducer, useRef,
} from 'react';
import type { ReactNode } from 'react';
import { createBackend, type ConnectionStatus, type GameBackend } from '../backend';
import { GameError, type PublicGameState, type RoomState } from '../game/types';
import { sanitizeName } from '../game/logic';
import { errorMessage, T } from '../ui/text';
import { audio } from '../audio/audioManager';

export type Screen =
  | 'home' | 'create' | 'join' | 'lobby' | 'game' | 'result' | 'settings' | 'tutorial';

export interface AppState {
  screen: Screen;
  playerName: string;
  room: RoomState | null;
  game: PublicGameState | null;
  /** The player's own secret, tagged with the game it belongs to. */
  mySecret: { gameId: string; characterId: number } | null;
  eliminated: number[];
  connection: ConnectionStatus;
  opponentOnline: boolean;
  busy: string | null;
  toast: string | null;
  errorToast: string | null;
}

type Action =
  | { type: 'goto'; screen: Screen }
  | { type: 'setName'; name: string }
  | { type: 'room'; room: RoomState }
  | { type: 'game'; game: PublicGameState }
  | { type: 'secret'; characterId: number; gameId: string }
  | { type: 'connection'; status: ConnectionStatus }
  | { type: 'presence'; online: boolean }
  | { type: 'busy'; label: string | null }
  | { type: 'toast'; message: string | null }
  | { type: 'error'; message: string | null }
  | { type: 'toggleEliminate'; characterId: number }
  | { type: 'resetToHome' };

const NAME_KEY = 'ana-meno-name';
const SESSION_ROOM_KEY = 'ana-meno-room-id';

function initialState(): AppState {
  return {
    screen: 'home',
    playerName: localStorage.getItem(NAME_KEY) ?? '',
    room: null,
    game: null,
    mySecret: null,
    eliminated: [],
    connection: 'connecting',
    opponentOnline: false,
    busy: null,
    toast: null,
    errorToast: null,
  };
}

function reducer(state: AppState, action: Action): AppState {
  switch (action.type) {
    case 'goto': {
      // Never navigate "back" into the lobby while a game is already live —
      // the game event can arrive before the lobby navigation dispatch.
      if (action.screen === 'lobby' && state.game) {
        return { ...state, screen: state.game.status === 'active' ? 'game' : 'result' };
      }
      return { ...state, screen: action.screen };
    }
    case 'setName':
      return { ...state, playerName: action.name };
    case 'room': {
      let screen = state.screen;
      // Both seats filled while we sit in the lobby -> game screen comes via
      // the game event; a fresh rematch game also flows through 'game'.
      return { ...state, room: action.room, screen };
    }
    case 'game': {
      const prev = state.game;
      const isNewGame = !prev || prev.id !== action.game.id;
      let screen = state.screen;
      if (action.game.status === 'active' && (screen === 'lobby' || screen === 'result' || isNewGame)) {
        screen = 'game';
      }
      if (action.game.status === 'finished' && screen === 'game') {
        screen = 'result';
      }
      return {
        ...state,
        game: action.game,
        screen,
        eliminated: isNewGame ? [] : state.eliminated,
        // Keep the secret if it already belongs to this game — it can arrive
        // before the first game event (this was wiping the guest's secret).
        mySecret: state.mySecret?.gameId === action.game.id ? state.mySecret : null,
      };
    }
    case 'secret':
      return { ...state, mySecret: { gameId: action.gameId, characterId: action.characterId } };
    case 'connection':
      return { ...state, connection: action.status };
    case 'presence':
      return { ...state, opponentOnline: action.online };
    case 'busy':
      return { ...state, busy: action.label };
    case 'toast':
      return { ...state, toast: action.message };
    case 'error':
      return { ...state, errorToast: action.message };
    case 'toggleEliminate': {
      const has = state.eliminated.includes(action.characterId);
      return {
        ...state,
        eliminated: has
          ? state.eliminated.filter((id) => id !== action.characterId)
          : [...state.eliminated, action.characterId],
      };
    }
    case 'resetToHome':
      return {
        ...initialState(),
        playerName: state.playerName,
        connection: state.connection,
        screen: 'home',
      };
    default:
      return state;
  }
}

export interface AppApi {
  state: AppState;
  backend: GameBackend;
  playerId: string;
  goto: (screen: Screen) => void;
  setName: (name: string) => void;
  createRoom: () => Promise<void>;
  joinRoom: (code: string) => Promise<void>;
  leaveToHome: () => Promise<void>;
  askQuestion: (questionId: string) => Promise<void>;
  answerQuestion: (answer: boolean) => Promise<void>;
  submitGuess: (characterId: number) => Promise<void>;
  reportTimeout: () => Promise<void>;
  requestRematch: () => Promise<void>;
  toggleEliminate: (characterId: number) => void;
  showToast: (message: string) => void;
  dismissError: () => void;
}

const AppContext = createContext<AppApi | null>(null);

export function AppProvider({ children }: { children: ReactNode }) {
  const [state, dispatch] = useReducer(reducer, undefined, initialState);
  const backendRef = useRef<GameBackend | null>(null);
  if (!backendRef.current) backendRef.current = createBackend();
  const backend = backendRef.current;

  const prevPresence = useRef(true);
  const stateRef = useRef(state);
  stateRef.current = state;

  useEffect(() => {
    backend.setListeners({
      onRoomUpdate: (room) => {
        const prev = stateRef.current.room;
        dispatch({ type: 'room', room });
        if (prev && prev.players.length === 1 && room.players.length === 2) {
          audio.play('join');
        }
      },
      onGameUpdate: (game) => {
        const prev = stateRef.current.game;
        dispatch({ type: 'game', game });
        if (game.status === 'finished' && prev?.status !== 'finished') {
          const iWon = game.winnerId === backend.getPlayerId();
          audio.play(iWon ? 'win' : 'lose');
        }
      },
      onSecret: (characterId, gameId) => dispatch({ type: 'secret', characterId, gameId }),
      onConnectionChange: (status) => dispatch({ type: 'connection', status }),
      onOpponentPresence: (online) => {
        dispatch({ type: 'presence', online });
        if (!online && prevPresence.current) {
          dispatch({ type: 'toast', message: T.opponentDisconnected });
        } else if (online && !prevPresence.current) {
          dispatch({ type: 'toast', message: T.opponentReconnected });
        }
        prevPresence.current = online;
      },
    });

    let cancelled = false;
    void (async () => {
      try {
        await backend.init();
        if (cancelled) return;
        dispatch({ type: 'connection', status: 'connected' });
        // Resume a room after a reload (reconnection support).
        const savedRoom = sessionStorage.getItem(SESSION_ROOM_KEY);
        if (savedRoom) {
          const room = await backend.resumeRoom(savedRoom);
          if (room && room.status !== 'expired' && room.status !== 'finished') {
            dispatch({ type: 'room', room });
            dispatch({ type: 'goto', screen: room.players.length === 2 ? 'game' : 'lobby' });
          } else {
            sessionStorage.removeItem(SESSION_ROOM_KEY);
          }
        }
      } catch (err) {
        if (!cancelled) {
          dispatch({ type: 'connection', status: 'offline' });
          console.error('backend init failed', err);
        }
      }
    })();

    const onOnline = () => {
      dispatch({ type: 'connection', status: 'reconnecting' });
      void backend.init()
        .then(() => dispatch({ type: 'connection', status: 'connected' }))
        .catch(() => dispatch({ type: 'connection', status: 'offline' }));
    };
    const onOffline = () => dispatch({ type: 'connection', status: 'offline' });
    window.addEventListener('online', onOnline);
    window.addEventListener('offline', onOffline);
    return () => {
      cancelled = true;
      window.removeEventListener('online', onOnline);
      window.removeEventListener('offline', onOffline);
      backend.destroy();
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const fail = useCallback((err: unknown) => {
    const code = err instanceof GameError ? err.code : undefined;
    dispatch({ type: 'error', message: errorMessage(code) });
    if (!(err instanceof GameError)) console.error(err);
  }, []);

  const withBusy = useCallback(async (label: string, fn: () => Promise<void>) => {
    dispatch({ type: 'busy', label });
    try {
      await fn();
    } catch (err) {
      fail(err);
    } finally {
      dispatch({ type: 'busy', label: null });
    }
  }, [fail]);

  const api = useMemo<AppApi>(() => ({
    state,
    backend,
    playerId: backend.getPlayerId(),
    goto: (screen) => dispatch({ type: 'goto', screen }),
    setName: (name) => {
      dispatch({ type: 'setName', name });
      localStorage.setItem(NAME_KEY, name);
    },
    createRoom: () => withBusy(T.creatingRoom, async () => {
      const room = await backend.createRoom(sanitizeName(state.playerName));
      sessionStorage.setItem(SESSION_ROOM_KEY, room.id);
      dispatch({ type: 'room', room });
      dispatch({ type: 'goto', screen: 'lobby' });
    }),
    joinRoom: (code) => withBusy(T.joining, async () => {
      const room = await backend.joinRoom(code, sanitizeName(state.playerName));
      sessionStorage.setItem(SESSION_ROOM_KEY, room.id);
      dispatch({ type: 'room', room });
      dispatch({ type: 'goto', screen: 'lobby' });
      audio.play('join');
    }),
    leaveToHome: async () => {
      sessionStorage.removeItem(SESSION_ROOM_KEY);
      dispatch({ type: 'resetToHome' });
      try {
        await backend.leaveRoom();
      } catch { /* best effort */ }
    },
    askQuestion: async (questionId) => {
      try {
        audio.play('question');
        await backend.askQuestion(questionId);
      } catch (err) { fail(err); }
    },
    answerQuestion: async (answer) => {
      try {
        audio.play(answer ? 'answerYes' : 'answerNo');
        await backend.answerQuestion(answer);
      } catch (err) { fail(err); }
    },
    submitGuess: async (characterId) => {
      try {
        audio.play('guess');
        await backend.submitGuess(characterId);
      } catch (err) { fail(err); }
    },
    reportTimeout: async () => {
      try {
        await backend.timeoutTurn();
      } catch { /* opponent probably reported it first — harmless */ }
    },
    requestRematch: async () => {
      try {
        await backend.requestRematch();
      } catch (err) { fail(err); }
    },
    toggleEliminate: (characterId) => {
      const eliminated = state.eliminated.includes(characterId);
      audio.play(eliminated ? 'restore' : 'flip');
      dispatch({ type: 'toggleEliminate', characterId });
    },
    showToast: (message) => dispatch({ type: 'toast', message }),
    dismissError: () => dispatch({ type: 'error', message: null }),
  }), [state, backend, withBusy, fail]);

  // Auto-dismiss toasts.
  useEffect(() => {
    if (!state.toast) return;
    const t = setTimeout(() => dispatch({ type: 'toast', message: null }), 3500);
    return () => clearTimeout(t);
  }, [state.toast]);

  useEffect(() => {
    if (!state.errorToast) return;
    const t = setTimeout(() => dispatch({ type: 'error', message: null }), 4000);
    return () => clearTimeout(t);
  }, [state.errorToast]);

  return <AppContext.Provider value={api}>{children}</AppContext.Provider>;
}

export function useApp(): AppApi {
  const ctx = useContext(AppContext);
  if (!ctx) throw new Error('useApp must be used inside AppProvider');
  return ctx;
}
