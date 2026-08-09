import { useEffect, useState } from 'react';
import { useApp } from '../state/store';
import { T } from '../ui/text';

/** Network status banner — only visible when not cleanly connected. */
export function ConnectionBanner() {
  const { state } = useApp();
  if (state.connection === 'connected') return null;
  const label =
    state.connection === 'connecting' ? T.connecting
    : state.connection === 'reconnecting' ? T.reconnecting
    : T.offline;
  const tone = state.connection === 'offline' ? 'bg-coral text-white' : 'bg-sun text-navy-deep';
  return (
    <div
      role="status"
      className={`${tone} text-center font-bold text-sm py-1.5 animate-pulse-soft`}
      style={{ paddingTop: 'max(env(safe-area-inset-top, 0px), 0.375rem)' }}
    >
      {label}
    </div>
  );
}

export function Toasts() {
  const { state, dismissError } = useApp();
  return (
    <div className="fixed inset-x-0 bottom-4 z-[70] flex flex-col items-center gap-2 px-4 pointer-events-none"
      style={{ bottom: 'calc(env(safe-area-inset-bottom, 0px) + 1rem)' }}>
      {state.toast && (
        <div role="status" className="pointer-events-auto bg-navy text-white font-bold rounded-2xl px-5 py-3 shadow-pop animate-slide-up text-center">
          {state.toast}
        </div>
      )}
      {state.errorToast && (
        <button
          onClick={dismissError}
          role="alert"
          className="pointer-events-auto bg-coral text-white font-bold rounded-2xl px-5 py-3 shadow-pop animate-shake text-center"
        >
          {state.errorToast}
        </button>
      )}
    </div>
  );
}

/** Gentle recommendation to rotate back to portrait on small landscape screens. */
export function LandscapeHint() {
  const [landscape, setLandscape] = useState(false);
  useEffect(() => {
    const mq = window.matchMedia('(orientation: landscape) and (max-height: 480px)');
    const update = () => setLandscape(mq.matches);
    update();
    mq.addEventListener('change', update);
    return () => mq.removeEventListener('change', update);
  }, []);
  if (!landscape) return null;
  return (
    <div className="fixed top-0 inset-x-0 z-[65] bg-navy text-white text-center text-sm font-bold py-1">
      {T.landscapeHint}
    </div>
  );
}
