// tk-house-style: ESLint flat config (CommonJS form).
// Functional-core / imperative-shell defaults. Tier-2.
//
// Install:
//   pnpm add -D eslint @typescript-eslint/parser @typescript-eslint/eslint-plugin eslint-plugin-functional
//
// Copy this file to the project root as `eslint.config.cjs`.

const tsParser = require("@typescript-eslint/parser");
const tsPlugin = require("@typescript-eslint/eslint-plugin");
const functional = require("eslint-plugin-functional");

/** @type {import("eslint").Linter.FlatConfig[]} */
module.exports = [
  {
    files: ["**/*.ts", "**/*.tsx"],
    languageOptions: {
      parser: tsParser,
      parserOptions: {
        project: true,
        ecmaVersion: 2022,
        sourceType: "module",
      },
    },
    plugins: {
      "@typescript-eslint": tsPlugin,
      functional,
    },
    rules: {
      // ---- functional / immutability ---------------------------------
      "functional/no-let": "error",
      "functional/no-loop-statements": "warn",
      "functional/no-throw-statements": "error",
      "functional/no-this-expressions": "error",
      // "functional/no-classes": "error",
      //   ^ commented out: too disruptive for framework code (NestJS,
      //     React class components, etc.). Opt-in per project.
      "functional/immutable-data": "error",
      "functional/prefer-readonly-type": "warn",
      "functional/prefer-tacit": "warn",
      "functional/type-declaration-immutability": "warn",

      // ---- TypeScript core -------------------------------------------
      "@typescript-eslint/no-explicit-any": [
        "error",
        // Allow when justified with a leading comment containing
        // `eslint-disable-next-line @typescript-eslint/no-explicit-any`.
        { ignoreRestArgs: false },
      ],
      "@typescript-eslint/no-non-null-assertion": "error",
      "@typescript-eslint/strict-boolean-expressions": [
        "error",
        {
          allowString: false,
          allowNumber: false,
          allowNullableObject: false,
        },
      ],
      "@typescript-eslint/switch-exhaustiveness-check": "error",
      "@typescript-eslint/consistent-type-imports": "error",
    },
  },

  // ---- Shell / boundary code: relax purity rules -------------------
  // Files under src/shell/** are allowed to throw, mutate I/O state,
  // call Date.now / Math.random / crypto.randomUUID, etc.
  {
    files: ["src/shell/**/*.ts", "src/shell/**/*.tsx"],
    rules: {
      "functional/no-throw-statements": "off",
      "functional/immutable-data": "off",
      "functional/no-loop-statements": "off",
    },
  },

  // ---- Tests: relaxed ---------------------------------------------
  {
    files: ["**/*.test.ts", "**/*.spec.ts", "test/**/*.ts"],
    rules: {
      "functional/no-let": "off",
      "functional/immutable-data": "off",
      "functional/no-throw-statements": "off",
      "@typescript-eslint/no-explicit-any": "off",
    },
  },
];
