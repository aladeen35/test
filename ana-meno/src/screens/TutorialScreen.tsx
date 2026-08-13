import { useState } from 'react';
import { useApp } from '../state/store';
import { T } from '../ui/text';
import { audio } from '../audio/audioManager';
import { CHARACTERS, MYSTERY_IMAGE_URL } from '../game/characters';
import { CharacterImage } from '../components/CharacterImage';

function StepIllustration({ step }: { step: number }) {
  const sample = CHARACTERS.slice(0, 3);
  switch (step) {
    case 0:
      return <img src={MYSTERY_IMAGE_URL} alt="" className="w-28 h-28 rounded-2xl mx-auto animate-floaty" />;
    case 1:
      return (
        <div className="mx-auto card px-4 py-3 max-w-[240px] font-bold text-navy text-sm">
          «هل ترتدي الشخصية نظارة؟» 🤔
          <div className="flex justify-center gap-2 mt-2">
            <span className="rounded-full bg-mint text-white font-black px-4 py-0.5">نعم</span>
            <span className="rounded-full bg-coral text-white font-black px-4 py-0.5">لا</span>
          </div>
        </div>
      );
    case 2:
      return (
        <div className="flex justify-center gap-2">
          {sample.map((c, i) => (
            <div key={c.id} className="relative w-20">
              <CharacterImage character={c} className={`rounded-xl ${i !== 1 ? 'opacity-40 saturate-0' : ''}`} />
              {i !== 1 && <span className="absolute inset-0 flex items-center justify-center text-coral text-3xl font-black">✕</span>}
            </div>
          ))}
        </div>
      );
    case 3:
      return <div className="text-7xl animate-wiggle" aria-hidden="true">🎯</div>;
    default:
      return <div className="text-7xl animate-floaty" aria-hidden="true">⭐</div>;
  }
}

export function TutorialScreen() {
  const { goto } = useApp();
  const [step, setStep] = useState(0);
  const steps = T.tutorialSteps;
  const last = step === steps.length - 1;
  const current = steps[step];

  const advance = () => {
    audio.play('click');
    if (last) goto('home');
    else setStep((s) => s + 1);
  };

  return (
    <div className="screen gap-4">
      <header className="flex items-center justify-between pt-2">
        <h1 className="panel-royal px-6 py-1.5 text-xl font-black">{T.tutorialTitle}</h1>
        <button className="font-bold text-navy/50 underline px-2 py-1" onClick={() => { audio.play('click'); goto('home'); }}>
          {T.skip}
        </button>
      </header>

      <main className="flex-1 flex flex-col items-center justify-center gap-6 text-center">
        <div className="text-5xl" aria-hidden="true">{current.icon}</div>
        <StepIllustration step={step} />
        <div>
          <h2 className="text-2xl font-black text-navy mb-2">{current.title}</h2>
          <p className="font-bold text-navy/70 text-lg max-w-xs mx-auto leading-relaxed">{current.text}</p>
        </div>
      </main>

      <div className="flex items-center justify-center gap-1.5 pb-1" aria-hidden="true">
        {steps.map((_, i) => (
          <span key={i} className={`h-2 rounded-full transition-all ${i === step ? 'w-6 bg-royal' : 'w-2 bg-sky-light'}`} />
        ))}
      </div>
      <button className="btn-primary text-xl" onClick={advance}>
        {last ? T.done : T.next}
      </button>
    </div>
  );
}
