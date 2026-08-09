import { useState } from 'react';
import { useApp } from '../state/store';
import { getQuestion } from '../game/questions';
import { T } from '../ui/text';

/** Collapsible history of asked questions and their answers. */
export function QuestionLog() {
  const { state, playerId } = useApp();
  const [open, setOpen] = useState(false);
  const game = state.game;
  const room = state.room;
  if (!game || !room) return null;

  const answered = game.history.filter((h) => h.answer !== null);
  const nameOf = (id: string) => room.players.find((p) => p.id === id)?.name ?? '';

  return (
    <div className="card overflow-hidden">
      <button
        onClick={() => setOpen((v) => !v)}
        aria-expanded={open}
        className="w-full flex items-center justify-between px-4 py-2.5 font-extrabold text-navy"
      >
        <span>
          📜 {T.questionLog}
          <span className="ltr-num text-navy/50 text-sm font-bold"> ({answered.length})</span>
        </span>
        <span aria-hidden="true" className={`transition-transform ${open ? 'rotate-180' : ''}`}>▾</span>
      </button>
      {open && (
        <ul className="px-4 pb-3 flex flex-col gap-1.5 max-h-48 overflow-y-auto">
          {answered.length === 0 && (
            <li className="text-navy/50 font-semibold text-sm py-1">لا توجد أسئلة بعد.</li>
          )}
          {[...answered].reverse().map((h) => {
            const q = getQuestion(h.questionId);
            const mine = h.askerId === playerId;
            return (
              <li key={h.id} className="flex items-start justify-between gap-2 rounded-xl bg-sky-pale px-3 py-2">
                <div className="min-w-0">
                  <div className="text-xs font-bold text-navy/50">{mine ? 'أنت' : nameOf(h.askerId)}</div>
                  <div className="text-sm font-bold text-navy leading-snug">{q?.textAr}</div>
                </div>
                <span
                  className={`shrink-0 rounded-full px-3 py-0.5 text-sm font-black text-white ${h.answer ? 'bg-mint' : 'bg-coral'}`}
                >
                  {h.answer ? T.yes : T.no}
                </span>
              </li>
            );
          })}
        </ul>
      )}
    </div>
  );
}
