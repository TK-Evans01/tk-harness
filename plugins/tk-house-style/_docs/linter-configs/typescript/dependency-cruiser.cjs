// tk-house-style: dependency-cruiser config.
// Architectural lint for functional-core / imperative-shell layout.
//
//   src/core/**   - pure domain logic. No I/O. No impure globals.
//   src/shell/**  - I/O, framework glue, side effects.
//   src/app/**    - composition root. May import core + shell.
//
// Copy to project root as `.dependency-cruiser.cjs`.

/** @type {import("dependency-cruiser").IConfiguration} */
module.exports = {
  forbidden: [
    {
      name: "no-orphans",
      severity: "warn",
      comment:
        "Orphan modules are usually dead code. Whitelist via doNotFollow.",
      from: {
        orphan: true,
        pathNot: [
          "(^|/)\\.[^/]+\\.(js|cjs|mjs|ts|json)$",
          "\\.d\\.ts$",
          "(^|/)tsconfig\\.json$",
          "(^|/)(babel|webpack)\\.config\\.(js|cjs|mjs|ts|json)$",
        ],
      },
      to: {},
    },

    {
      name: "core-no-shell",
      severity: "error",
      comment: "Functional core must not import the imperative shell.",
      from: { path: "^src/core/" },
      to: { path: "^src/shell/" },
    },

    {
      name: "core-no-app",
      severity: "error",
      comment: "Functional core must not import the composition root.",
      from: { path: "^src/core/" },
      to: { path: "^src/app/" },
    },

    {
      name: "shell-no-app",
      severity: "error",
      comment: "Shell must not depend on the composition root.",
      from: { path: "^src/shell/" },
      to: { path: "^src/app/" },
    },

    {
      name: "no-impure-in-core",
      severity: "error",
      comment:
        "Tier-2: no Date / Math.random / crypto / fs / net / process / timers in core.",
      from: { path: "^src/core/" },
      to: {
        path: [
          "^node:fs",
          "^node:net",
          "^node:http",
          "^node:https",
          "^node:dns",
          "^node:os",
          "^node:process",
          "^node:child_process",
          "^node:crypto",
          "^node:timers",
          "^fs$",
          "^net$",
          "^http$",
          "^https$",
          "^crypto$",
          "^os$",
          "^child_process$",
        ],
      },
    },

    {
      name: "no-circular",
      severity: "error",
      comment: "Circular dependencies are forbidden.",
      from: {},
      to: { circular: true },
    },

    {
      name: "no-deprecated-core",
      severity: "warn",
      from: {},
      to: { dependencyTypes: ["deprecated"] },
    },

    {
      name: "not-to-test",
      severity: "error",
      comment: "Production code must not import test files.",
      from: { pathNot: "\\.(test|spec)\\.(js|cjs|mjs|ts|tsx)$" },
      to: { path: "\\.(test|spec)\\.(js|cjs|mjs|ts|tsx)$" },
    },

    {
      name: "not-to-dev-dep",
      severity: "error",
      comment: "Production code must only depend on production dependencies.",
      from: {
        path: "^(src)/",
        pathNot: "\\.(test|spec)\\.(js|cjs|mjs|ts|tsx)$",
      },
      to: { dependencyTypes: ["npm-dev"] },
    },
  ],

  options: {
    doNotFollow: { path: "node_modules" },
    tsConfig: { fileName: "tsconfig.json" },
    enhancedResolveOptions: {
      exportsFields: ["exports"],
      conditionNames: ["import", "require", "node", "default"],
    },
    reporterOptions: {
      dot: { collapsePattern: "node_modules/(@[^/]+/[^/]+|[^/]+)" },
    },
  },
};
