import { useApp } from '../state/store';
import { T } from '../ui/text';
import { audio } from '../audio/audioManager';

const OPTIONS = [
  { icon: '🎲', label: T.gameMode, value: T.normalMode },
  { icon: '🃏', label: 'عدد الشخصيات', value: T.characterCount },
  { icon: '✨', label: 'الاختيار', value: T.randomSelection },
  { icon: '🧑‍🤝‍🧑', label: 'التنوع', value: T.diverseCharacters },
  { icon: '💼', label: 'المهن', value: T.diverseProfessions },
];

export function CreateRoomScreen() {
  const { state, createRoom, goto } = useApp();

  return (
    <div className="screen gap-4">
      <header className="flex items-center gap-3 pt-2">
        <button className="btn-soft !min-h-11 !px-3" onClick={() => { audio.play('click'); goto('home'); }} aria-label={T.backToHome}>
          →
        </button>
        <h1 className="text-2xl font-black text-navy">{T.createRoomTitle}</h1>
      </header>

      <main className="flex flex-col gap-3 flex-1">
        <div className="card p-4 flex flex-col gap-3">
          {OPTIONS.map((o) => (
            <div key={o.label} className="flex items-center justify-between rounded-xl bg-sky-pale px-3 py-2.5">
              <span className="font-bold text-navy/70">
                <span aria-hidden="true">{o.icon}</span> {o.label}
              </span>
              <span className="font-extrabold text-navy">{o.value}</span>
            </div>
          ))}
        </div>
        <p className="text-center font-semibold text-navy/60 text-sm px-4">
          سيحصل كل لاعب على شخصية سرية عشوائية من بين 30 شخصية.
        </p>
      </main>

      <button
        className="btn-primary text-xl"
        onClick={() => { audio.play('click'); void createRoom(); }}
        disabled={state.busy !== null}
      >
        {state.busy ?? `🚀 ${T.createRoomBtn}`}
      </button>
    </div>
  );
}
