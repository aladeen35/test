"use client";
import { useSyncExternalStore } from "react";

const noop = () => () => {};

function subscribeOnline(cb: () => void) {
  window.addEventListener("online", cb);
  window.addEventListener("offline", cb);
  return () => { window.removeEventListener("online", cb); window.removeEventListener("offline", cb); };
}

/** navigator.onLine as React state (assumes online during SSR). */
export function useOnline() {
  return useSyncExternalStore(subscribeOnline, () => navigator.onLine, () => true);
}

/** A browser-only value read once (false/null during SSR). */
export function useClientValue<T>(read: () => T, server: T) {
  return useSyncExternalStore(noop, read, () => server);
}
