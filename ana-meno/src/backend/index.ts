import type { GameBackend } from './types';
import { LocalBackend } from './localBackend';
import { SupabaseBackend } from './supabaseBackend';

export type { GameBackend, BackendListeners, ConnectionStatus } from './types';

/**
 * Chooses the backend from environment configuration.
 * - With VITE_SUPABASE_URL + VITE_SUPABASE_ANON_KEY: real Supabase multiplayer.
 * - Without credentials (development fallback): LocalBackend, which plays
 *   between two tabs of the same browser. Production must configure Supabase.
 */
export function createBackend(): GameBackend {
  const url = import.meta.env.VITE_SUPABASE_URL as string | undefined;
  const anonKey = import.meta.env.VITE_SUPABASE_ANON_KEY as string | undefined;
  if (url && anonKey) {
    return new SupabaseBackend(url, anonKey);
  }
  if (import.meta.env.PROD) {
    console.warn(
      'VITE_SUPABASE_URL / VITE_SUPABASE_ANON_KEY are not set — falling back to the ' +
      'local two-tab development backend. Configure Supabase for real multiplayer.',
    );
  }
  return new LocalBackend();
}

export function isLocalBackend(backend: GameBackend): boolean {
  return backend.kind === 'local';
}
