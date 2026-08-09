import { useEffect, useRef, useState } from 'react';
import { useApp } from '../state/store';
import { TURN_SECONDS, formatDuration } from '../game/logic';
import { T } from '../ui/text';
import { audio } from '../audio/audioManager';

/** Compact game header: players, turn indicator, question counts, timer. */
export function PlayerHeader() {
  const { state, playerId, reportTimeout } = useApp();
  const { game, room } = state;
  const [now, setNow] = useState(Date.now());
  const reportedFor = useRef<number | null>(null);

  const remaining = game
    ? Math.max(0, Math.ceil((game.turnStartedAt + TURN_SECONDS * 1000 - now) / 1000))
    : TURN_SECONDS;

  useEffect(() => {
    const t = setInterval(() => setNow(Date.now()), 500);
    return () => clearInterval(t);
  }, []);

  useEffect(() => {
    if (!game || game.status !== 'active') return;
    if (remaining === 0 && reportedFor.current !== game.turnStartedAt) {
      reportedFor.current = game.turnStartedAt;
      void reportTimeout();
    }
    if (remaining === 10) audio.play('tick');
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [remaining, game?.turnStartedAt, game?.status]);

  if (!game || !room) return null;

  const me = room.players.find((p) => p.id === playerId);
  const opponent = room.players.find((p) => p.id !== playerId);
  const myTurn = game.currentTurnPlayerId === playerId;
  const elapsed = Math.max(0, Math.floor((now - game.startedAt) / 1000));
  const myQuestions = game.questionsUsed[playerId] ?? 0;
  const opponentQuestions = opponent ? game.questionsUsed[opponent.id] ?? 0 : 0;

  return (
    <div className="card px-3 py-2 flex items-center gap-2 text-sm">
      {/* me */}
      <div className={`flex-1 min-w-0 rounded-xl px-2 py-1 ${myTurn ? 'bg-sun-pale ring-2 ring-sun' : ''}`}>
        <div className="font-extrabold text-navy truncate">{me?.name}</div>
        <div className="text-xs text-navy/60 font-semibold">
          {T.questionsLabel}: <span className="ltr-num">{myQuestions}</span>
        </div>
      </div>

      {/* center: turn + timer */}
      <div className="text-center shrink-0 px-1">
        <div className={`font-black text-sm ${myTurn ? 'text-mint' : 'text-navy/60'}`}>
          {myTurn ? T.yourTurn : T.opponentTurn}
        </div>
        <div
          className={`ltr-num font-black text-lg leading-none ${remaining <= 10 ? 'text-coral animate-pulse-soft' : 'text-navy'}`}
          aria-label={`${T.timeLabel}: ${remaining} ثانية`}
        >
          {formatDuration(remaining)}
        </div>
        <div className="text-[10px] text-navy/50 font-semibold ltr-num">{formatDuration(elapsed)} ⏱</div>
      </div>

      {/* opponent */}
      <div className={`flex-1 min-w-0 rounded-xl px-2 py-1 text-end ${!myTurn ? 'bg-sky-pale ring-2 ring-sky' : ''}`}>
        <div className="font-extrabold text-navy truncate flex items-center justify-end gap-1">
          {!state.opponentOnline && <span title={T.opponentDisconnected} aria-label={T.opponentDisconnected}>📴</span>}
          <span className="truncate">{opponent?.name}</span>
        </div>
        <div className="text-xs text-navy/60 font-semibold">
          {T.questionsLabel}: <span className="ltr-num">{opponentQuestions}</span>
        </div>
      </div>
    </div>
  );
}
