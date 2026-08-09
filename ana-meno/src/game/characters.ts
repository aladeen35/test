import type { Character } from './types';
import rawCharacters from '../data/characters.json';

export const CHARACTERS: Character[] = rawCharacters as Character[];

const byId = new Map(CHARACTERS.map((c) => [c.id, c]));

export function getCharacter(id: number): Character | undefined {
  return byId.get(id);
}

export function characterImageUrl(c: Character): string {
  return `${import.meta.env.BASE_URL}assets/characters/${c.slug}.svg`;
}

export const MYSTERY_IMAGE_URL = `${import.meta.env.BASE_URL}assets/characters/mystery.svg`;
