import { useState } from 'react';
import { useApp } from '../state/store';
import { T } from '../ui/text';
import { audio } from '../audio/audioManager';

function Seat({ name, filled, seatLabel }: { name: string | null; filled: boolean; seatLabel: string }) {
  return (
    <div
      className={`card flex-1 flex flex-col items-center gap-2 py-5 px-3 transition-all
        ${filled ? 'animate-pop-in' : 'opacity-80 border-2 border-dashed border-sky'}`}
    >
      <div className={`w-16 h-16 rounded-full flex items-center justify-center text-3xl
        ${filled ? 'bg-sun-pale' : 'bg-sky-pale animate-pulse-soft'}`} aria-hidden="true">
        {filled ? '😀' : '⏳'}
      </div>
      <div className="text-xs font-bold text-navy/50">{seatLabel}</div>
      <div className="font-extrabold text-navy text-lg text-center leading-tight">
        {filled ? name : T.waitingSeat}
      </div>
    </div>
  );
}

export function LobbyScreen() {
  const { state, leaveToHome } = useApp();
  const [copied, setCopied] = useState(false);
  const room = state.room;
  if (!room) return null;

  const p1 = room.players.find((p) => p.seat === 1) ?? null;
  const p2 = room.players.find((p) => p.seat === 2) ?? null;
  const full = !!p1 && !!p2;

  const copyCode = async () => {
    audio.play('click');
    try {
      await navigator.clipboard.writeText(room.code);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch { /* clipboard unavailable */ }
  };

  const shareCode = async () => {
    audio.play('click');
    const text = `العب معي "أنا مِنو 🤔"! رمز الغرفة: ${room.code}`;
    if (navigator.share) {
      try { await navigator.share({ title: T.appName, text }); } catch { /* cancelled */ }
    } else {
      await copyCode();
    }
  };

  return (
    <div className="screen gap-5">
      <header className="text-center pt-3">
        <h1 className="text-3xl font-black text-navy">{full ? T.playersReady : T.waitingForPlayer2}</h1>
      </header>

      <div className="card px-5 py-4 text-center">
        <div className="font-bold text-navy/60 mb-1">{T.roomCode}</div>
        <div className="ltr-num text-5xl font-black text-royal tracking-[0.3em] animate-pop-in select-all">
          {room.code}
        </div>
        <div className="flex gap-2 mt-4">
          <button className="btn-soft flex-1" onClick={copyCode}>
            {copied ? T.copied : `📋 ${T.copyCode}`}
          </button>
          <button className="btn-soft flex-1" onClick={shareCode}>
            📤 {T.shareCode}
          </button>
        </div>
      </div>

      <div className="flex items-stretch gap-3">
        <Seat name={p1?.name ?? null} filled={!!p1} seatLabel={T.player1} />
        <div className="self-center font-black text-2xl text-coral" aria-hidden="true">VS</div>
        <Seat name={p2?.name ?? null} filled={!!p2} seatLabel={T.player2} />
      </div>

      {full && (
        <div className="text-center font-extrabold text-mint text-lg animate-pulse-soft" role="status">
          {T.preparingGame}
        </div>
      )}

      <div className="flex-1" />
      <button className="btn-soft" onClick={() => { audio.play('click'); void leaveToHome(); }}>
        {T.backToHome}
      </button>
    </div>
  );
}
