import { useState } from 'react';
import { Modal } from './Modal';
import { QUESTIONS, QUESTION_CATEGORIES } from '../game/questions';
import type { QuestionCategoryId } from '../game/types';
import { T } from '../ui/text';
import { audio } from '../audio/audioManager';

interface QuestionSheetProps {
  open: boolean;
  onClose: () => void;
  onAsk: (questionId: string) => void;
}

export function QuestionSheet({ open, onClose, onAsk }: QuestionSheetProps) {
  const [category, setCategory] = useState<QuestionCategoryId>('appearance');
  const questions = QUESTIONS.filter((q) => q.category === category);

  return (
    <Modal open={open} onClose={onClose} title={T.askQuestion}>
      <div className="flex gap-1.5 overflow-x-auto pb-2 -mx-1 px-1" role="tablist" aria-label="فئات الأسئلة">
        {QUESTION_CATEGORIES.map((cat) => (
          <button
            key={cat.id}
            role="tab"
            aria-selected={category === cat.id}
            onClick={() => { audio.play('click'); setCategory(cat.id); }}
            className={`shrink-0 rounded-full px-4 py-2 font-bold text-sm transition-colors
              ${category === cat.id ? 'bg-royal text-white' : 'bg-sky-pale text-navy'}`}
          >
            <span aria-hidden="true">{cat.icon}</span> {cat.labelAr}
          </button>
        ))}
      </div>
      <ul className="flex flex-col gap-2 mt-1">
        {questions.map((q) => (
          <li key={q.id}>
            <button
              onClick={() => onAsk(q.id)}
              className="w-full text-start rounded-2xl border-2 border-sky-light bg-white px-4 py-3
                font-bold text-navy hover:border-royal active:scale-[0.99] transition-all"
            >
              {q.textAr}
            </button>
          </li>
        ))}
      </ul>
    </Modal>
  );
}
