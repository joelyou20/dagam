module.exports = [
  { ignores: ["Resources/Hex/Engine/battle.js"] },
  {
    files: ["Resources/Hex/Engine/*.js"],
    languageOptions: { ecmaVersion: 2022, sourceType: "script" },
    // Modules share one QuickJS scope; cross-file globals are intentionally resolved at bundle time.
    rules: {
      "constructor-super": "error",
      "no-dupe-args": "error",
      "no-dupe-keys": "error",
      "no-duplicate-case": "error",
      "no-invalid-regexp": "error",
      "no-unreachable": "error",
      "valid-typeof": "error"
    }
  }
];
