import { useState } from 'react';
import { useApp } from '../state/store';
import { Confetti } from '../components/Confetti';
import { CharacterCard } from '../components/CharacterCard';
import { getCharacter } from '../game/characters';
import { computeScore, formatDuration } from '../game/logic';
import { T } from '../ui/text';
import { audio } from '../audio/audioManager';

export function ResultScreen() {
  const { state, playerId, requestRematch, leaveToHome } = useApp();
  const [rematchSent, setRematchSent] = useState(false);
  const game = state.game;
  const room = state.room;
  if (!game || !room || game.status !== 'finished') return null;

  const iWon = game.winnerId === playerId;
  const winner = room.players.find((p) => p.id === game.winnerId);
  const opponent = room.players.find((p) => p.id !== playerId);

  // The character the winner had to find = the loser's... no: the winner
  // guessed the OPPONENT's secret. Show the character that decided the game.
  const decisiveSecretOwner = game.winnerId && game.winReason === 'correct_guess'
    ? room.players.find((p) => p.id !== game.winnerId)?.id
    : opponent?.id;
  const revealedId = game.revealedSecrets && decisiveSecretOwner
    ? game.revealedSecrets[decisiveSecretOwner]
    : null;
  const revealed = revealedId ? getCharacter(revealedId) : null;

  const myQuestions = game.questionsUsed[playerId] ?? 0;
  const elapsed = game.finishedAt ? Math.floor((game.finishedAt - game.startedAt) / 1000) : 0;
  const winnerScore = game.winnerId ? game.scores[game.winnerId] ?? 0 : 0;
  const breakdown = computeScore(game.winnerId ? game.questionsUsed[game.winnerId] ?? 0 : 0, elapsed);

  const subtitle = game.winReason === 'forfeit'
    ? T.youWonByForfeit
    : game.winReason === 'opponent_wrong_guess'
      ? (iWon ? T.wonByWrongGuess : T.lostByWrongGuess)
      : null;

  const opponentWantsRematch = room.players.find((p) => p.id !== playerId)?.rematchRequested ?? false;

  const rematch = () => {
    audio.play('click');
    setRematchSent(true);
    void requestRematch();
  };

  return (
    <div className="screen gap-4 text-center">
      {iWon && <Confetti />}
      <header className="pt-6">
        <div className="text-6xl mb-2 animate-pop-in" aria-hidden="true">{iWon ? '🏆' : '🤭'}</div>
        <h1 className="text-3xl font-black text-navy">{iWon ? T.wellDone : T.badLuck}</h1>
        <p className="font-bold text-navy/60 mt-1">{T.winnerIs}</p>
        <p className="text-2xl font-black text-royal">{winner?.name}</p>
        {subtitle && (
          <p className="font-semibold text-navy/60 text-sm mt-1">{subtitle}</p>
        )}
      </header>

      <div className="card p-4 grid grid-cols-3 gap-2">
        <div>
          <div className="text-xs font-bold text-navy/50">{T.questionsLabel}</div>
          <div className="ltr-num text-2xl font-black text-navy">{myQuestions}</div>
        </div>
        <div>
          <div className="text-xs font-bold text-navy/50">{T.timeLabel}</div>
          <div className="ltr-num text-2xl font-black text-navy">{formatDuration(elapsed)}</div>
        </div>
        <div>
          <div className="text-xs font-bold text-navy/50">{T.scoreLabel}</div>
          <div className="ltr-num text-2xl font-black text-sun-deep">{iWon ? winnerScore : 0}</div>
        </div>
        {iWon && (
          <div className="col-span-3 text-xs font-semibold text-navy/50">
            <span className="ltr-num">{breakdown.base}</span> نقطة أساسية + <span className="ltr-num">{breakdown.timeBonus}</span> مكافأة السرعة
          </div>
        )}
      </div>

      {revealed && (
        <div>
          <p className="font-extrabold text-navy mb-2">
            {game.winReason === 'correct_guess' && iWon ? T.characterWas : T.correctCharacterWas}
          </p>
          <div className="w-36 mx-auto animate-pop-in">
            <CharacterCard character={revealed} size="large" showProfession />
          </div>
        </div>
      )}

      <div className="flex-1" />

      {opponentWantsRematch && !rematchSent && (
        <p className="font-bold text-mint animate-pulse-soft" role="status">{T.rematchRequested}</p>
      )}
      {rematchSent && (
        <p className="font-bold text-navy/60 animate-pulse-soft" role="status">{T.waitingOtherPlayer}</p>
      )}

      <div className="flex flex-col gap-2 pb-2">
        <button className="btn-primary text-xl" onClick={rematch} disabled={rematchSent}>
          🔄 {T.playAgain}
        </button>
        <button className="btn-soft" onClick={() => { audio.play('click'); void leaveToHome(); }}>
          🏠 {T.exitToHome}
        </button>
      </div>
    </div>
  );
}
