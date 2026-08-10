import { useState } from 'react';
import type { Character } from '../game/types';
import { characterImageUrl, customCharacterImageUrl } from '../game/characters';

// Ids whose custom artwork failed to load this session (avoids repeated 404s).
const missingCustom = new Set<number>();

interface CharacterImageProps {
  character: Character;
  className?: string;
  alt?: string;
}

/**
 * Character portrait with custom-artwork support: tries the numbered file
 * the owner can drop in (assets/characters/custom/<id>.png) and falls back
 * to the generated SVG when it doesn't exist. No code changes are needed
 * to swap in hand-made art — same mechanism as the brand logo.
 */
export function CharacterImage({ character, className, alt = '' }: CharacterImageProps) {
  const [useCustom, setUseCustom] = useState(!missingCustom.has(character.id));
  return (
    <img
      src={useCustom ? customCharacterImageUrl(character) : characterImageUrl(character)}
      alt={alt}
      loading="lazy"
      draggable={false}
      className={className}
      onError={() => {
        missingCustom.add(character.id);
        setUseCustom(false);
      }}
    />
  );
}
