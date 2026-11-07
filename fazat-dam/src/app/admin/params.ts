export function sp(v: string | string[] | undefined) {
  return typeof v === "string" && v.length < 100 ? v : undefined;
}
export const isUuid = (v?: string) => Boolean(v && /^[0-9a-f-]{36}$/.test(v));
export const isDate = (v?: string) => Boolean(v && /^\d{4}-\d{2}-\d{2}$/.test(v));
export const isCountry = (v?: string) => v === "SD" || v === "SA";
