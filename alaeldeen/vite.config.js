import { defineConfig } from "vite";
import tailwindcss from "@tailwindcss/vite";

// base "./" keeps every URL relative, so the built site works from any sub-folder
// (e.g. GitHub Pages at /test/alaeldeen/dist/).
export default defineConfig({
  base: "./",
  plugins: [tailwindcss()],
  build: {
    outDir: "dist",
    emptyOutDir: true,
    target: "es2020",
    chunkSizeWarningLimit: 900,
  },
});
