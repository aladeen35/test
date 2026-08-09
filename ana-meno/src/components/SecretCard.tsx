import { useState } from 'react';
import { getCharacter, characterImageUrl, MYSTERY_IMAGE_URL } from '../game/characters';
import { useApp } from '../state/store';
import { T } from '../ui/text';
import { audio } from '../audio/audioManager';

/**
 * The player's own secret character, shown as a small flippable chip so
 * nearby eyes don't see it by accident.
 */
export function SecretCard() {
  const { state } = useApp();
  const [revealed, setRevealed] = useState(false);
  const secret = state.mySecretId ? getCharacter(state.mySecretId) : null;

  return (
    <button
      type="button"
      onClick={() => { audio.play('click'); setRevealed((v) => !v); }}
      aria-label={revealed && secret ? `${T.yourSecretCharacter}: ${secret.name} — ${secret.professionAr}` : T.yourSecretCharacter}
      className="card flex items-center gap-3 px-3 py-2 w-full text-start active:scale-[0.99] transition-transform"
    >
      <img
        src={revealed && secret ? characterImageUrl(secret) : MYSTERY_IMAGE_URL}
        alt=""
        className="w-14 h-14 rounded-xl shrink-0"
        draggable={false}
      />
      <div className="min-w-0 flex-1">
        <div className="font-extrabold text-navy text-sm">{T.yourSecretCharacter}</div>
        {revealed && secret ? (
          <div className="font-bold text-royal truncate">
            {secret.name} · {secret.professionAr}
          </div>
        ) : (
          <div className="text-xs font-semibold text-navy/50">اضغط للكشف 👀</div>
        )}
      </div>
      <span className="text-navy/40 text-xl" aria-hidden="true">{revealed ? '🙈' : '👁️'}</span>
    </button>
  );
}
