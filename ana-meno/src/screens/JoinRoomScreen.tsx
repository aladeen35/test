import { useState } from 'react';
import { useApp } from '../state/store';
import { T } from '../ui/text';
import { ROOM_CODE_LENGTH, isValidRoomCode, normalizeRoomCode } from '../game/logic';
import { audio } from '../audio/audioManager';

export function JoinRoomScreen() {
  const { state, joinRoom, goto, showToast } = useApp();
  const [code, setCode] = useState('');

  const submit = () => {
    audio.play('click');
    if (!isValidRoomCode(code)) {
      showToast('رمز الغرفة غير صحيح.');
      return;
    }
    void joinRoom(normalizeRoomCode(code));
  };

  return (
    <div className="screen gap-4">
      <header className="flex items-center gap-3 pt-2">
        <button className="btn-soft !min-h-11 !px-3" onClick={() => { audio.play('click'); goto('home'); }} aria-label={T.backToHome}>
          →
        </button>
        <h1 className="text-2xl font-black text-navy">{T.joinRoomTitle}</h1>
      </header>

      <main className="flex flex-col items-center gap-4 flex-1 justify-center">
        <div className="text-6xl animate-floaty" aria-hidden="true">🔑</div>
        <label className="block w-full text-center">
          <span className="block font-extrabold text-navy mb-2 text-lg">{T.enterRoomCode}</span>
          <input
            className="input ltr-num !text-3xl !font-black text-center tracking-[0.35em] uppercase"
            value={code}
            onChange={(e) => setCode(e.target.value.toUpperCase())}
            onKeyDown={(e) => { if (e.key === 'Enter') submit(); }}
            maxLength={ROOM_CODE_LENGTH}
            placeholder="•••••"
            autoCapitalize="characters"
            autoCorrect="off"
            spellCheck={false}
            inputMode="text"
            aria-label={T.roomCode}
          />
        </label>
        <p className="text-sm font-semibold text-navy/60 text-center">
          اطلب الرمز المكوّن من 5 رموز من صديقك الذي أنشأ الغرفة.
        </p>
      </main>

      <button
        className="btn-primary text-xl"
        onClick={submit}
        disabled={state.busy !== null || code.length < ROOM_CODE_LENGTH}
      >
        {state.busy ?? `🎯 ${T.joinBtn}`}
      </button>
    </div>
  );
}
