const { defineConfig } = require('@playwright/test');

module.exports = defineConfig({
  testDir: '.',
  testMatch: 'test_*.js',
  use: {
    baseURL: 'http://localhost:8000',
    screenshot: 'only-on-failure',
  },
});
