import { useEffect } from 'react';
import type { ReactNode } from 'react';

interface ModalProps {
  open: boolean;
  onClose?: () => void;
  title?: string;
  children: ReactNode;
  /** bottom sheet on phones, centered dialog on wide screens */
  sheet?: boolean;
}

export function Modal({ open, onClose, title, children, sheet = true }: ModalProps) {
  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose?.();
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [open, onClose]);

  if (!open) return null;
  return (
    <div
      className={`fixed inset-0 z-50 flex ${sheet ? 'items-end sm:items-center' : 'items-center'} justify-center`}
      role="dialog"
      aria-modal="true"
      aria-label={title}
    >
      <button
        className="absolute inset-0 bg-navy-deep/50 backdrop-blur-[2px]"
        aria-label="إغلاق"
        onClick={onClose}
        tabIndex={-1}
      />
      <div
        className={`relative w-full sm:max-w-md bg-white shadow-pop animate-slide-up
          ${sheet ? 'rounded-t-blob sm:rounded-blob' : 'rounded-blob mx-4'}
          max-h-[88dvh] overflow-y-auto`}
        style={{ paddingBottom: 'max(env(safe-area-inset-bottom, 0px), 1rem)' }}
      >
        {title && (
          <div className="sticky top-0 bg-white/95 backdrop-blur rounded-t-blob px-5 pt-4 pb-2 flex items-center justify-between">
            <h2 className="text-xl font-extrabold text-navy">{title}</h2>
            {onClose && (
              <button
                onClick={onClose}
                aria-label="إغلاق"
                className="w-10 h-10 rounded-full bg-sky-pale text-navy font-black text-lg"
              >
                ✕
              </button>
            )}
          </div>
        )}
        <div className="px-5 pb-4 pt-2">{children}</div>
      </div>
    </div>
  );
}
