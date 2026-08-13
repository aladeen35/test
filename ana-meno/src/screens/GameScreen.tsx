import { useState } from 'react';
import { useApp } from '../state/store';
import { PlayerHeader } from '../components/PlayerHeader';
import { CharacterGrid } from '../components/CharacterGrid';
import { QuestionLog } from '../components/QuestionLog';
import { QuestionSheet } from '../components/QuestionSheet';
import { AnswerModal, WaitingAnswerModal, GuessModal } from '../components/GameModals';
import { SecretCard } from '../components/SecretCard';
import { CHARACTERS } from '../game/characters';
import { T } from '../ui/text';
import { audio } from '../audio/audioManager';

export function GameScreen() {
  const { state, playerId, askQuestion, toggleEliminate, leaveToHome } = useApp();
  const [questionSheetOpen, setQuestionSheetOpen] = useState(false);
  const [guessOpen, setGuessOpen] = useState(false);
  const [confirmLeave, setConfirmLeave] = useState(false);

  const game = state.game;
  if (!game || !state.room) {
    return (
      <div className="screen items-center justify-center">
        <div className="text-5xl animate-floaty" aria-hidden="true">🃏</div>
        <p className="font-extrabold text-navy/70 mt-3 animate-pulse-soft">{T.preparingCharacters}</p>
      </div>
    );
  }

  const myTurn = game.currentTurnPlayerId === playerId && game.status === 'active' && !game.pendingQuestion;
  const remainingCount = CHARACTERS.length - state.eliminated.length;

  const ask = async (questionId: string) => {
    setQuestionSheetOpen(false);
    await askQuestion(questionId);
  };

  return (
    <div className="screen !max-w-3xl gap-2.5">
      <PlayerHeader />
      <SecretCard />

      <div className="flex items-center justify-between px-1">
        <span className="font-bold text-navy/60 text-sm">
          {T.remaining}: <span className="ltr-num font-black text-navy">{remainingCount}</span> / <span className="ltr-num">30</span>
        </span>
        <button
          className="text-sm font-bold text-navy/50 underline"
          onClick={() => setConfirmLeave(true)}
        >
          {T.exitToHome}
        </button>
      </div>

      <main className="flex-1">
        <CharacterGrid
          eliminated={state.eliminated}
          onTap={(c) => toggleEliminate(c.id)}
        />
      </main>

      <QuestionLog />

      <div className="sticky bottom-0 -mx-4 px-4 pt-2 pb-1 backdrop-blur-[2px] bg-gradient-to-t from-white/60 via-white/40 to-transparent">
        <div className="flex gap-2">
          <button
            className="btn-secondary flex-[3] text-lg"
            onClick={() => { audio.play('click'); setQuestionSheetOpen(true); }}
            disabled={!myTurn}
          >
            ❓ {T.askQuestion}
          </button>
          <button
            className="btn-primary flex-[2] text-lg"
            onClick={() => { audio.play('click'); setGuessOpen(true); }}
            disabled={!myTurn}
          >
            🎯 {T.guessCharacter}
          </button>
        </div>
        {!myTurn && game.status === 'active' && (
          <p className="text-center text-xs font-bold text-navy/50 mt-1" role="status">
            {game.pendingQuestion
              ? (game.pendingQuestion.askerId === playerId ? T.waitingAnswer : T.answerTheQuestion)
              : T.opponentAsking}
          </p>
        )}
      </div>

      <QuestionSheet open={questionSheetOpen} onClose={() => setQuestionSheetOpen(false)} onAsk={ask} />
      <GuessModal open={guessOpen} onClose={() => setGuessOpen(false)} />
      <AnswerModal />
      <WaitingAnswerModal />

      {confirmLeave && (
        <div className="fixed inset-0 z-50 flex items-center justify-center px-6">
          <button className="absolute inset-0 bg-navy-deep/50" onClick={() => setConfirmLeave(false)} aria-label={T.cancel} />
          <div className="relative card p-6 text-center max-w-sm w-full animate-pop-in">
            <p className="text-xl font-black text-navy mb-2">{T.areYouSure}</p>
            <p className="font-semibold text-navy/60 mb-4 text-sm">إذا خرجت الآن سيفوز خصمك بالجولة.</p>
            <div className="flex flex-col gap-2">
              <button className="btn-danger" onClick={() => void leaveToHome()}>{T.exitToHome}</button>
              <button className="btn-soft" onClick={() => setConfirmLeave(false)}>{T.cancel}</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
