import type { Character, Question, QuestionCategoryId } from './types';
import rawQuestions from '../data/questions.json';

// Question texts/categories live in src/data/questions.json (shared with the
// SQL seed generator). Every question is deterministically answerable from
// character metadata — no subjective questions. The predicates live here.

export const QUESTION_CATEGORIES: { id: QuestionCategoryId; labelAr: string; icon: string }[] = [
  { id: 'appearance', labelAr: 'المظهر', icon: '🙂' },
  { id: 'profession', labelAr: 'المهنة', icon: '💼' },
  { id: 'clothing', labelAr: 'الملابس', icon: '👕' },
  { id: 'accessories', labelAr: 'الإكسسوارات', icon: '🎒' },
  { id: 'traits', labelAr: 'الصفات', icon: '✨' },
];

const PREDICATES: Record<string, (c: Character) => boolean> = {
  q_male: (c) => c.gender === 'male',
  q_female: (c) => c.gender === 'female',
  q_glasses: (c) => c.hasGlasses,
  q_beard: (c) => c.beardStyle !== 'none',
  q_short_hair: (c) => c.hairLength === 'short',
  q_long_hair: (c) => c.hairLength === 'long',
  q_black_hair: (c) => c.hairColor === 'black' && c.hairLength !== 'covered' && c.hairLength !== 'none',
  q_hijab: (c) => c.headwear === 'hijab',
  q_dark_skin: (c) => c.skinTone === 'dark',
  q_medicine: (c) => c.field === 'medicine',
  q_engineering: (c) => c.field === 'engineering',
  q_food: (c) => c.field === 'food',
  q_tech: (c) => c.field === 'tech',
  q_media: (c) => c.field === 'media',
  q_education: (c) => c.field === 'education',
  q_security: (c) => c.field === 'security',
  q_uniform: (c) => c.uniform,
  q_white_coat: (c) => c.clothing === 'whiteCoat',
  q_helmet: (c) => c.headwear === 'helmet' || c.headwear === 'fireHelmet',
  q_headwear: (c) => c.headwear !== 'none',
  q_suit: (c) => c.clothing === 'suit',
  q_hiviz: (c) => c.clothing === 'vest',
  q_stethoscope: (c) => c.accessory === 'stethoscope',
  q_camera: (c) => c.accessory === 'camera',
  q_device: (c) => ['laptop', 'tablet'].includes(c.accessory),
  q_tool: (c) => c.accessory !== 'none',
  q_office: (c) => c.worksInOffice,
  q_outdoors: (c) => c.worksOutdoors,
};

export const QUESTIONS: Question[] = (
  rawQuestions as { id: string; category: QuestionCategoryId; textAr: string }[]
).map((q) => {
  const test = PREDICATES[q.id];
  if (!test) throw new Error(`Missing predicate for question ${q.id}`);
  return { ...q, test };
});

const questionById = new Map(QUESTIONS.map((q) => [q.id, q]));

export function getQuestion(id: string): Question | undefined {
  return questionById.get(id);
}

export function isValidQuestionId(id: string): boolean {
  return questionById.has(id);
}

/** Deterministic true answer for a question about a character. */
export function answerFor(character: Character, questionId: string): boolean {
  const q = questionById.get(questionId);
  if (!q) throw new Error(`Unknown question: ${questionId}`);
  return q.test(character);
}
