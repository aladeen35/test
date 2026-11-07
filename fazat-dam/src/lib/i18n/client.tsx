"use client";
import { createContext, useContext } from "react";
import { dictionaries, type Dict, type Locale } from "./index";

const I18nContext = createContext<{ locale: Locale; t: Dict }>({ locale: "ar", t: dictionaries.ar });

export function I18nProvider({ locale, children }: { locale: Locale; children: React.ReactNode }) {
  return <I18nContext value={{ locale, t: dictionaries[locale] }}>{children}</I18nContext>;
}

export function useI18n() {
  return useContext(I18nContext);
}
