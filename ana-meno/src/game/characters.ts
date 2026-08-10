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

/**
 * Owner-provided artwork path: numbered PNGs (1.png … 30.png) dropped into
 * assets/characters/custom/ override the generated art per character.
 */
export function customCharacterImageUrl(c: Character): string {
  return `${import.meta.env.BASE_URL}assets/characters/custom/${c.id}.png`;
}

export const MYSTERY_IMAGE_URL = `${import.meta.env.BASE_URL}assets/characters/mystery.svg`;
