// eslint.config.js — build-rite standard config (flat config, ESLint 9+)
// Enforces br-clean-code.md rules where statically detectable.
// Copy to project root: cp .claude/templates/eslint.config.js eslint.config.js
//
// Required packages (install what applies to your stack):
//   npm i -D eslint @eslint/js eslint-plugin-unicorn eslint-plugin-sonarjs
//          eslint-plugin-security eslint-plugin-import eslint-plugin-n
//          @typescript-eslint/eslint-plugin @typescript-eslint/parser   # TS only
//          eslint-plugin-react eslint-plugin-react-hooks                 # React only
//          eslint-plugin-jsx-a11y                                        # React a11y

import js from "@eslint/js";
import unicorn from "eslint-plugin-unicorn";
import sonarjs from "eslint-plugin-sonarjs";
import security from "eslint-plugin-security";
import importPlugin from "eslint-plugin-import";

// Uncomment for TypeScript:
// import tsPlugin from "@typescript-eslint/eslint-plugin";
// import tsParser from "@typescript-eslint/parser";

// Uncomment for React:
// import react from "eslint-plugin-react";
// import reactHooks from "eslint-plugin-react-hooks";
// import a11y from "eslint-plugin-jsx-a11y";

export default [
  js.configs.recommended,

  {
    plugins: {
      unicorn,
      sonarjs,
      security,
      import: importPlugin,
    },

    rules: {
      // ── Naming (br-clean-code: Naming) ──────────────────────────────────
      "unicorn/prevent-abbreviations": ["warn", {
        replacements: {
          e: { event: true },
          err: { error: true },
          req: { request: true },
          res: { response: true },
          cb: { callback: true },
          fn: { function: false }, // fn is idiomatic in functional code
        },
      }],
      "unicorn/filename-case": ["warn", {
        cases: { camelCase: true, pascalCase: true, kebabCase: true },
      }],
      "id-length": ["warn", { min: 2, exceptions: ["_", "i", "j", "k", "x", "y", "z"] }],

      // ── Functions (br-clean-code: Functions) ─────────────────────────────
      "max-params": ["warn", { max: 3 }],
      "max-lines-per-function": ["warn", { max: 40, skipBlankLines: true, skipComments: true }],
      "complexity": ["warn", { max: 10 }],
      "max-depth": ["warn", { max: 3 }],
      "max-nested-callbacks": ["warn", { max: 2 }],
      "sonarjs/cognitive-complexity": ["warn", 15],
      "no-param-reassign": ["warn", { props: false }],

      // ── Dead code (br-clean-code: Comments / YAGNI) ──────────────────────
      "no-unused-vars": ["error", { argsIgnorePattern: "^_", varsIgnorePattern: "^_" }],
      "no-unreachable": "error",
      "no-empty": "error",
      "no-empty-function": ["warn", { allow: ["arrowFunctions"] }],
      "sonarjs/no-commented-out-code": "warn",

      // ── Magic values (br-clean-code: Functions) ──────────────────────────
      "no-magic-numbers": ["warn", {
        ignore: [-1, 0, 1, 2, 100],
        ignoreArrayIndexes: true,
        ignoreDefaultValues: true,
        ignoreClassFieldInitialValues: true,
      }],

      // ── Error handling (br-clean-code: Error Handling) ───────────────────
      "no-throw-literal": "error",
      "prefer-promise-reject-errors": "error",
      "unicorn/prefer-type-error": "error",
      "sonarjs/no-ignored-return": "error",

      // ── Null / undefined safety ──────────────────────────────────────────
      "unicorn/no-null": "warn",          // prefer undefined over null
      "eqeqeq": ["error", "always"],      // no == (use ===)
      "no-implicit-coercion": "warn",

      // ── Simplification (br-clean-code: KISS / DRY) ───────────────────────
      "sonarjs/no-duplicate-string": ["warn", { threshold: 3 }],
      "sonarjs/no-identical-functions": "error",
      "sonarjs/prefer-immediate-return": "warn",
      "unicorn/no-useless-undefined": "warn",
      "unicorn/prefer-ternary": ["warn", "onlySingleLine"],
      "prefer-const": "error",
      "no-var": "error",
      "object-shorthand": "warn",
      "prefer-arrow-callback": "warn",
      "prefer-template": "warn",
      "unicorn/prefer-includes": "error",
      "unicorn/prefer-string-slice": "error",
      "unicorn/no-array-for-each": "warn",   // prefer for..of

      // ── Security (br-clean-code: Security) ───────────────────────────────
      "security/detect-object-injection": "warn",
      "security/detect-non-literal-regexp": "warn",
      "security/detect-non-literal-fs-filename": "warn",
      "security/detect-possible-timing-attacks": "warn",
      "security/detect-eval-with-expression": "error",
      "no-eval": "error",
      "no-new-func": "error",
      "unicorn/no-document-cookie": "error",

      // ── Imports (br-clean-code: Dependency Management) ───────────────────
      "import/no-cycle": "warn",
      "import/no-unused-modules": "warn",
      "import/no-duplicates": "error",
      "import/first": "error",
      "unicorn/prefer-module": "warn",

      // ── Async / concurrency ──────────────────────────────────────────────
      "require-await": "warn",
      "no-async-promise-executor": "error",
      "no-await-in-loop": "warn",          // prefer Promise.all
      "unicorn/no-array-callback-reference": "warn",

      // ── Correctness (standard JS pitfalls) ───────────────────────────────
      "no-shadow": "warn",
      "no-use-before-define": ["error", { functions: false, classes: true }],
      "no-console": ["warn", { allow: ["warn", "error"] }],
      "no-debugger": "error",
      "no-alert": "error",
      "consistent-return": "warn",
      "default-case": "warn",
      "guard-for-in": "warn",
    },
  },

  // ── TypeScript overrides (uncomment if using TS) ────────────────────────
  // {
  //   files: ["**/*.ts", "**/*.tsx"],
  //   languageOptions: { parser: tsParser },
  //   plugins: { "@typescript-eslint": tsPlugin },
  //   rules: {
  //     ...tsPlugin.configs.recommended.rules,
  //     ...tsPlugin.configs["recommended-requiring-type-checking"].rules,
  //     "@typescript-eslint/no-explicit-any": "warn",
  //     "@typescript-eslint/no-floating-promises": "error",
  //     "@typescript-eslint/no-misused-promises": "error",
  //     "@typescript-eslint/explicit-function-return-type": ["warn", { allowExpressions: true }],
  //     "@typescript-eslint/consistent-type-imports": "warn",
  //     "@typescript-eslint/no-unnecessary-type-assertion": "warn",
  //     "@typescript-eslint/prefer-nullish-coalescing": "warn",
  //     "@typescript-eslint/prefer-optional-chain": "warn",
  //     "no-unused-vars": "off",
  //     "@typescript-eslint/no-unused-vars": ["error", { argsIgnorePattern: "^_" }],
  //   },
  // },

  // ── React overrides (uncomment if using React) ──────────────────────────
  // {
  //   files: ["**/*.{jsx,tsx}"],
  //   plugins: { react, "react-hooks": reactHooks, "jsx-a11y": a11y },
  //   rules: {
  //     ...react.configs.recommended.rules,
  //     ...reactHooks.configs.recommended.rules,
  //     ...a11y.configs.recommended.rules,
  //     "react/prop-types": "off",           // use TypeScript instead
  //     "react/react-in-jsx-scope": "off",   // not needed in React 17+
  //     "react-hooks/exhaustive-deps": "warn",
  //     "react/no-array-index-key": "warn",
  //     "react/jsx-no-useless-fragment": "warn",
  //   },
  // },

  // ── Test file overrides ─────────────────────────────────────────────────
  {
    files: ["**/*.test.{js,ts,jsx,tsx}", "**/*.spec.{js,ts,jsx,tsx}", "**/tests/**"],
    rules: {
      "no-magic-numbers": "off",
      "max-lines-per-function": "off",
      "sonarjs/no-duplicate-string": "off",
      "no-unused-expressions": "off",
    },
  },

  // ── Config / script overrides ───────────────────────────────────────────
  {
    files: ["*.config.{js,ts,mjs}", "scripts/**"],
    rules: {
      "no-console": "off",
      "import/no-unused-modules": "off",
    },
  },

  {
    ignores: [
      "dist/**", "build/**", ".next/**", "coverage/**",
      "node_modules/**", "*.min.js", "*.generated.*",
    ],
  },
];
