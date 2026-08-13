import { useState } from 'react';
import { useApp } from '../state/store';
import { T } from '../ui/text';
import { audio, type AudioPrefs } from '../audio/audioManager';
import { LogoMark } from '../components/Logo';

function ToggleRow({ icon, label, value, onToggle }: {
  icon: string; label: string; value: boolean; onToggle: () => void;
}) {
  return (
    <button
      onClick={onToggle}
      role="switch"
      aria-checked={value}
      className="w-full flex items-center justify-between rounded-2xl bg-white px-4 py-3 shadow-card"
    >
      <span className="font-extrabold text-navy text-lg">
        <span aria-hidden="true">{icon}</span> {label}
      </span>
      <span className={`rounded-full px-4 py-1 font-black text-white ${value ? 'bg-mint' : 'bg-navy/30'}`}>
        {value ? T.on : T.off}
      </span>
    </button>
  );
}

export function SettingsScreen() {
  const { goto } = useApp();
  const [prefs, setPrefs] = useState<AudioPrefs>(audio.getPrefs());

  const toggle = (key: keyof AudioPrefs) => {
    audio.setPref(key, !prefs[key]);
    if (key === 'music' && !prefs.music && audio.getPrefs().sounds) {
      audio.startMusic();
    }
    setPrefs(audio.getPrefs());
    audio.play('click');
  };

  return (
    <div className="screen gap-4">
      <header className="flex items-center gap-3 pt-2">
        <button className="btn-soft !min-h-11 !px-3" onClick={() => { audio.play('click'); goto('home'); }} aria-label={T.backToHome}>
          →
        </button>
        <h1 className="panel-royal flex-1 text-center px-4 py-1.5 text-xl font-black">{T.settings}</h1>
      </header>

      <main className="flex flex-col gap-3 flex-1">
        <ToggleRow icon="🔊" label={T.sounds} value={prefs.sounds} onToggle={() => toggle('sounds')} />
        <ToggleRow icon="🎵" label={T.music} value={prefs.music} onToggle={() => toggle('music')} />
        <ToggleRow icon="✨" label={T.effects} value={prefs.effects} onToggle={() => toggle('effects')} />

        <button className="btn-soft justify-start text-lg" onClick={() => { audio.play('click'); goto('tutorial'); }}>
          📖 {T.howToPlay}
        </button>

        <div className="card p-5 text-center mt-2">
          <div className="flex justify-center mb-2"><LogoMark size={64} /></div>
          <h2 className="font-black text-navy text-xl">{T.appName}</h2>
          <p className="font-bold text-navy/60">{T.aboutText}</p>
          <p className="font-semibold text-navy/40 text-sm mt-1">{T.version}</p>
        </div>
      </main>
    </div>
  );
}
