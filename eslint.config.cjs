module.exports = [
  {
    ignores: [
      "inst/bindings/**",
      "inst/www/wa/**",
      "vendor/**",
      "website/**"
    ]
  },
  {
    files: ["inst/www/webawesome-init.js"],
    languageOptions: {
      ecmaVersion: "latest",
      sourceType: "module",
      globals: {
        URL: "readonly",
        console: "readonly",
        document: "readonly",
        window: "readonly"
      }
    },
    rules: {
      curly: ["error", "all"],
      eqeqeq: "error",
      "no-undef": "error",
      "no-unused-vars": ["error", { args: "none" }]
    }
  }
];
