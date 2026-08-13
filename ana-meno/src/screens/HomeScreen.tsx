import { useState } from 'react';
import { useApp } from '../state/store';
import { LogoMark, LogoTitle } from '../components/Logo';
import { T } from '../ui/text';
import { isValidName, MAX_NAME_LENGTH } from '../game/logic';
import { CHARACTERS } from '../game/characters';
import { CharacterImage } from '../components/CharacterImage';
import { audio } from '../audio/audioManager';

// Official brand artwork, used untouched when present in public/assets/.
// Falls back to the generated logo composition if the file is missing.
const BRAND_LOGO_URL = `${import.meta.env.BASE_URL}assets/logo.png`;

// A small floating cast around the title (doctor, engineer, chef, pilot,
// designer, teacher) — matches the brand's "wall of character cards".
const CAST_SLUGS = [
  'doctor-female', 'engineer-male', 'chef-male', 'pilot-female', 'fashion-designer-female', 'teacher-male',
];

function FloatingCast() {
  const cast = CAST_SLUGS
    .map((slug) => CHARACTERS.find((c) => c.slug === slug)!)
    .filter(Boolean);
  const positions = [
    'top-2 -right-2 rotate-6', 'top-10 -left-3 -rotate-6', '-top-4 right-16 -rotate-3',
    'top-24 -right-6 rotate-3', 'top-28 -left-6 rotate-6', '-top-2 left-16 rotate-2',
  ];
  return (
    <div className="relative h-40 w-full max-w-xs mx-auto pointer-events-none" aria-hidden="true">
      {cast.map((c, i) => (
        <span
          key={c.slug}
          className={`absolute animate-floaty ${positions[i]}`}
          style={{ animationDelay: `${i * 0.45}s` }}
        >
          <CharacterImage character={c} className="w-16 h-16 rounded-xl shadow-card" />
        </span>
      ))}
      <div className="absolute inset-0 flex items-center justify-center">
        <LogoMark size={104} />
      </div>
    </div>
  );
}

export function HomeScreen() {
  const { state, setName, goto, showToast } = useApp();
  const [nameDraft, setNameDraft] = useState(state.playerName);
  const [brandLogoOk, setBrandLogoOk] = useState(true);
  const prefs = audio.getPrefs();
  const [, forceRender] = useState(0);

  const commitNameAnd = (next: 'create' | 'join') => {
    audio.play('click');
    if (prefs.sounds && prefs.music && !audio.isMusicPlaying()) audio.startMusic();
    if (!isValidName(nameDraft)) {
      showToast(T.nameTooShort);
      return;
    }
    setName(nameDraft);
    goto(next);
  };

  const toggleSounds = () => {
    audio.toggleSounds();
    if (!audio.getPrefs().sounds) audio.stopMusic();
    forceRender((n) => n + 1);
    audio.play('click');
  };

  return (
    <div className="screen justify-between gap-4">
      <header className="text-center pt-2">
        {brandLogoOk ? (
          <img
            src={BRAND_LOGO_URL}
            alt={T.appName}
            onError={() => setBrandLogoOk(false)}
            draggable={false}
            className="w-full max-w-sm mx-auto rounded-blob animate-pop-in"
          />
        ) : (
          <>
            <FloatingCast />
            <div className="panel-royal inline-block px-8 py-2 mt-3">
              <LogoTitle className="text-4xl" light />
              <p className="font-bold text-white/90 text-base mt-0.5">{T.tagline}</p>
            </div>
          </>
        )}
      </header>

      <main className="flex flex-col gap-3">
        <label className="block">
          <span className="block font-extrabold text-navy mb-1.5">{T.yourName}</span>
          <input
            className="input text-center"
            value={nameDraft}
            onChange={(e) => setNameDraft(e.target.value)}
            placeholder={T.enterYourName}
            maxLength={MAX_NAME_LENGTH}
            autoComplete="nickname"
            enterKeyHint="done"
          />
        </label>

        <button className="btn-primary text-xl" onClick={() => commitNameAnd('create')}>
          🎮 {T.createGame}
        </button>
        <button className="btn-secondary text-xl" onClick={() => commitNameAnd('join')}>
          🔑 {T.joinGame}
        </button>
        <div className="flex gap-3">
          <button className="btn-soft flex-1" onClick={() => { audio.play('click'); goto('tutorial'); }}>
            📖 {T.howToPlay}
          </button>
          <button className="btn-soft flex-1" onClick={() => { audio.play('click'); goto('settings'); }}>
            ⚙️ {T.settings}
          </button>
        </div>
        <button
          className="mx-auto rounded-full bg-white/80 px-4 py-1.5 font-bold text-navy/70 text-sm shadow-card"
          onClick={toggleSounds}
          aria-pressed={prefs.sounds}
        >
          {prefs.sounds ? `🔊 ${T.soundsOn}` : `🔇 ${T.soundsOff}`}
        </button>
      </main>

      <footer className="text-center pb-1">
        <p className="font-bold text-navy/60 text-sm">{T.twoPlayerBlurb} · {T.howBlurb}</p>
      </footer>
    </div>
  );
}
