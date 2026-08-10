import { useState } from 'react';
import { Modal } from './Modal';
import { CharacterGrid } from './CharacterGrid';
import { CharacterCard } from './CharacterCard';
import { getCharacter } from '../game/characters';
import { getQuestion } from '../game/questions';
import { useApp } from '../state/store';
import { T } from '../ui/text';

/** Defender modal: shows the opponent's question with يمكن نعم/لا only. */
export function AnswerModal() {
  const { state, playerId, answerQuestion } = useApp();
  const game = state.game;
  const pending = game?.pendingQuestion ?? null;
  const mustAnswer = !!pending && pending.askerId !== playerId && game?.status === 'active';
  const question = pending ? getQuestion(pending.questionId) : null;
  const [sending, setSending] = useState(false);

  const respond = async (answer: boolean) => {
    if (sending) return;
    setSending(true);
    try {
      await answerQuestion(answer);
    } finally {
      setSending(false);
    }
  };

  return (
    <Modal open={mustAnswer} title={T.answerTheQuestion}>
      <div className="text-center py-2">
        <div className="text-5xl mb-3" aria-hidden="true">❓</div>
        <p className="text-xl font-extrabold text-navy mb-1">{T.question}:</p>
        <p className="text-2xl font-black text-royal leading-relaxed mb-6">{question?.textAr}</p>
        <p className="text-sm font-semibold text-navy/60 mb-4">
          أجب حسب شخصيتك السرية {state.mySecret ? `(${getCharacter(state.mySecret.characterId)?.name})` : ''}
        </p>
        <div className="flex justify-center gap-4">
          <button className="btn-yes" onClick={() => respond(true)} disabled={sending}>{T.yes}</button>
          <button className="btn-no" onClick={() => respond(false)} disabled={sending}>{T.no}</button>
        </div>
      </div>
    </Modal>
  );
}

/** Asker's waiting state while the defender answers. */
export function WaitingAnswerModal() {
  const { state, playerId } = useApp();
  const game = state.game;
  const pending = game?.pendingQuestion ?? null;
  const waiting = !!pending && pending.askerId === playerId && game?.status === 'active';
  const question = pending ? getQuestion(pending.questionId) : null;

  return (
    <Modal open={waiting}>
      <div className="text-center py-4">
        <div className="text-4xl mb-3 animate-floaty inline-block" aria-hidden="true">🤔</div>
        <p className="text-lg font-extrabold text-navy mb-1">{question?.textAr}</p>
        <p className="font-bold text-navy/60 animate-pulse-soft">{T.waitingAnswer}</p>
      </div>
    </Modal>
  );
}

/** Final-guess flow: pick a character, then confirm. */
export function GuessModal({ open, onClose }: { open: boolean; onClose: () => void }) {
  const { state, submitGuess } = useApp();
  const [selectedId, setSelectedId] = useState<number | null>(null);
  const [sending, setSending] = useState(false);
  const selected = selectedId ? getCharacter(selectedId) : null;

  const close = () => {
    setSelectedId(null);
    onClose();
  };

  const confirm = async () => {
    if (!selectedId || sending) return;
    setSending(true);
    try {
      await submitGuess(selectedId);
      close();
    } finally {
      setSending(false);
    }
  };

  return (
    <>
      <Modal open={open && !selected} onClose={close} title={T.guessCharacter}>
        <p className="font-bold text-navy/70 mb-3">{T.chooseCharacterToGuess}</p>
        <CharacterGrid
          eliminated={state.eliminated}
          onTap={(c) => setSelectedId(c.id)}
        />
      </Modal>

      <Modal open={open && !!selected} onClose={() => setSelectedId(null)} sheet={false}>
        {selected && (
          <div className="text-center py-2">
            <p className="text-2xl font-black text-navy mb-4">{T.areYouSure}</p>
            <div className="w-40 mx-auto mb-4">
              <CharacterCard character={selected} size="large" />
            </div>
            <div className="flex flex-col gap-2">
              <button className="btn-primary text-lg" onClick={confirm} disabled={sending}>
                {T.confirmGuess}
              </button>
              <button className="btn-soft" onClick={() => setSelectedId(null)} disabled={sending}>
                {T.cancel}
              </button>
            </div>
          </div>
        )}
      </Modal>
    </>
  );
}
