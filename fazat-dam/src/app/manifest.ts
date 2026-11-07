import type { MetadataRoute } from "next";

export default function manifest(): MetadataRoute.Manifest {
  return {
    id: "/",
    name: "فزعة دم — FAZAT DAM",
    short_name: "فزعة دم",
    description: "منصة إنسانية تربط المتبرعين بالدم بالمرضى وأسرهم في السودان والسعودية — Your Support Saves Lives.",
    lang: "ar",
    dir: "rtl",
    start_url: "/?source=pwa",
    scope: "/",
    display: "standalone",
    orientation: "portrait",
    background_color: "#F4F6F8",
    theme_color: "#C62828",
    categories: ["health", "medical", "social"],
    icons: [
      { src: "/icons/icon-192.png", sizes: "192x192", type: "image/png", purpose: "any" },
      { src: "/icons/icon-512.png", sizes: "512x512", type: "image/png", purpose: "any" },
      { src: "/icons/maskable-512.png", sizes: "512x512", type: "image/png", purpose: "maskable" },
    ],
    shortcuts: [
      { name: "طلب دم عاجل", short_name: "طلب دم", url: "/requests/new", icons: [{ src: "/icons/icon-192.png", sizes: "192x192" }] },
      { name: "أريد التبرع", short_name: "تبرع", url: "/donate", icons: [{ src: "/icons/icon-192.png", sizes: "192x192" }] },
    ],
  };
}
