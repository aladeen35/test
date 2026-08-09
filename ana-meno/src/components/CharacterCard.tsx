import { memo } from 'react';
import type { Character } from '../game/types';
import { characterImageUrl } from '../game/characters';

interface CharacterCardProps {
  character: Character;
  eliminated?: boolean;
  onTap?: (c: Character) => void;
  selected?: boolean;
  showProfession?: boolean;
  size?: 'grid' | 'large';
}

export const CharacterCard = memo(function CharacterCard({
  character, eliminated = false, onTap, selected = false, showProfession = false, size = 'grid',
}: CharacterCardProps) {
  const label = eliminated
    ? `${character.name} — مستبعدة. اضغط لإلغاء الاستبعاد`
    : character.name;

  return (
    <button
      type="button"
      onClick={onTap ? () => onTap(character) : undefined}
      aria-pressed={eliminated || selected}
      aria-label={label}
      className={`relative w-full rounded-2xl bg-white p-1.5 pb-1 text-center transition-all duration-150
        shadow-card focus-visible:outline focus-visible:outline-4 focus-visible:outline-sun/70
        ${eliminated ? 'scale-[0.96]' : 'active:scale-[0.97]'}
        ${selected ? 'ring-4 ring-sun' : ''}`}
    >
      <div className="relative overflow-hidden rounded-xl">
        <img
          src={characterImageUrl(character)}
          alt=""
          loading="lazy"
          draggable={false}
          className={`w-full aspect-square transition-all duration-200 ${eliminated ? 'opacity-45 saturate-[0.25]' : ''}`}
        />
        {eliminated && (
          <div className="absolute inset-0 flex items-center justify-center bg-navy-deep/25 rounded-xl">
            <span className="text-coral-deep text-5xl font-black drop-shadow-[0_1px_0_white]" aria-hidden="true">✕</span>
          </div>
        )}
      </div>
      <div className={`font-bold leading-tight py-0.5 ${size === 'large' ? 'text-lg' : 'text-sm'} ${eliminated ? 'text-navy/45 line-through' : 'text-navy'}`}>
        {character.name}
      </div>
      {showProfession && (
        <div className="text-xs font-semibold text-navy/60 pb-1">{character.professionAr}</div>
      )}
    </button>
  );
});
