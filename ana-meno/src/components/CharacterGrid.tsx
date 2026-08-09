import type { Character } from '../game/types';
import { CHARACTERS } from '../game/characters';
import { CharacterCard } from './CharacterCard';

interface CharacterGridProps {
  eliminated: number[];
  onTap?: (c: Character) => void;
  selectedId?: number | null;
}

export function CharacterGrid({ eliminated, onTap, selectedId = null }: CharacterGridProps) {
  return (
    <div className="grid grid-cols-3 min-[480px]:grid-cols-4 md:grid-cols-5 gap-2">
      {CHARACTERS.map((c) => (
        <CharacterCard
          key={c.id}
          character={c}
          eliminated={eliminated.includes(c.id)}
          selected={selectedId === c.id}
          onTap={onTap}
        />
      ))}
    </div>
  );
}
