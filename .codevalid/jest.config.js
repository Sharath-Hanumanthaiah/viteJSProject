/**
 * CodeValid Jest config — tests live under .codevalid/ (rootDir here) while
 * TypeScript + node_modules resolve from the installable package (monorepo-safe
 * via CODEVALID_PACKAGE_ROOT). Using the package as rootDir breaks testMatch for
 * paths under .codevalid/, so module paths point at the package explicitly.
 *
 * ESM note: package.json has "type":"module" which makes several Jest transitive
 * deps (ansi-styles v6, chalk v5, wrap-ansi) pure-ESM only. We therefore run
 * Jest in native ESM mode via NODE_OPTIONS=--experimental-vm-modules and use
 * ts-jest with useESM:true so TypeScript test files are compiled to ESM output.
 *
 * moduleDirectories must NOT include absolute paths — doing so flattens the
 * node_modules tree and bypasses nested package hoisting, causing Jest to load
 * ansi-styles v6 (ESM) from the top-level instead of the nested v5 (CJS) that
 * pretty-format actually requires.  The default ["node_modules"] lets Jest walk
 * up the directory tree and respect nested node_modules correctly.
 */
const path = require("path");

const codevalidDir = __dirname;
const appRoot = path.resolve(codevalidDir, "..");
const rel =
  process.env.CODEVALID_PACKAGE_ROOT != null &&
  String(process.env.CODEVALID_PACKAGE_ROOT).trim() !== ""
    ? String(process.env.CODEVALID_PACKAGE_ROOT).trim().replace(new RegExp("^/+"), "")
    : "";
const packageRoot = rel ? path.join(appRoot, rel) : appRoot;
const pkgTsconfig = (() => {
  const candidate = path.join(packageRoot, "tsconfig.json");
  try { require("fs").accessSync(candidate); return candidate; } catch (_) {}
  // Fall back to the tsconfig bundled with the codevalid directory
  return path.join(codevalidDir, "tsconfig.json");
})();

module.exports = {
  rootDir: codevalidDir,
  testEnvironment: "node",
  testMatch: ["**/*.ts"],
  extensionsToTreatAsEsm: [".ts"],
  // Use default "node_modules" resolution — do NOT list absolute paths here.
  // Absolute entries (e.g. "/app/node_modules") flatten the tree and cause
  // Jest to resolve ansi-styles to the top-level ESM v6 instead of the nested
  // CJS v5 that pretty-format and other Jest internals actually require.
  moduleDirectories: ["node_modules"],
  transform: {
    '^.+\\.ts$': [
      "ts-jest",
      {
        useESM: true,
        tsconfig: pkgTsconfig,
        compilerOptions: {
          module: "ESNext",
          moduleResolution: "bundler",
          types: ["node", "jest"],
        },
        diagnostics: { ignoreCodes: [5107] },
      },
    ],
  },
  verbose: true,
  silent: false,
};
