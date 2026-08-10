import { getCharacter, characterImageUrl, MYSTERY_IMAGE_URL } from '../game/characters';
import { useApp } from '../state/store';
import { T } from '../ui/text';

/**
 * The player's own secret character — always visible, since each player
 * plays on their own device.
 */
export function SecretCard() {
  const { state } = useApp();
  const secret = state.mySecret && state.mySecret.gameId === state.game?.id
    ? getCharacter(state.mySecret.characterId)
    : null;

  return (
    <div
      role="status"
      aria-label={secret ? `${T.yourSecretCharacter}: ${secret.name} — ${secret.professionAr}` : T.yourSecretCharacter}
      className="card flex items-center gap-3 px-3 py-2 w-full ring-2 ring-sun"
    >
      <img
        src={secret ? characterImageUrl(secret) : MYSTERY_IMAGE_URL}
        alt=""
        className="w-14 h-14 rounded-xl shrink-0"
        draggable={false}
      />
      <div className="min-w-0 flex-1">
        <div className="font-extrabold text-navy text-sm">🕵️ {T.yourSecretCharacter}</div>
        {secret ? (
          <div className="font-black text-royal text-lg leading-tight truncate">
            {secret.name} · {secret.professionAr}
          </div>
        ) : (
          <div className="text-xs font-semibold text-navy/50 animate-pulse-soft">{T.preparingCharacters}</div>
        )}
      </div>
      <span className="text-xs font-bold text-navy/40 shrink-0 text-center leading-tight" aria-hidden="true">
        خصمك<br />يخمّنها
      </span>
    </div>
  );
}
