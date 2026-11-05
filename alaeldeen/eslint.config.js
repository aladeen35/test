import js from "@eslint/js";
import globals from "globals";

export default [
  { ignores: ["dist/**", "node_modules/**", "src/cinema/legacy-motion.js"] },
  js.configs.recommended,
  {
    files: ["**/*.js"],
    languageOptions: { ecmaVersion: 2023, sourceType: "module", globals: { ...globals.browser } },
    rules: { "no-unused-vars": ["error", { args: "none", caughtErrors: "none" }] },
  },
  { files: ["js/**/*.js"], languageOptions: { sourceType: "script" } },
  { files: ["public/sw.js"], languageOptions: { sourceType: "script", globals: { ...globals.serviceworker } } },
  { files: ["vite.config.js", "eslint.config.js"], languageOptions: { globals: { ...globals.node } } },
  { files: ["tools/**/*.cjs"], languageOptions: { sourceType: "commonjs", globals: { ...globals.node, ...globals.browser } } },
];
