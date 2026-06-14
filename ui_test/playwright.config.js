import { defineConfig, devices } from "@playwright/test";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const projectRoot = path.resolve(__dirname, "../..");

export default defineConfig({
  testDir: "./tests",
  outputDir: "./recordings/test-results",
  fullyParallel: false,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 1 : 0,
  workers: 1,
  reporter: [
    ["list"],
    ["html", { outputFolder: "./recordings/report", open: "never" }],
    ["json", { outputFile: "./recordings/test-results.json" }],
  ],
  use: {
    baseURL: "http://localhost:5173",
    trace: "on",
    video: "on",
    screenshot: "on",
    headless: true,
  },
  projects: [
    {
      name: "chromium",
      use: { ...devices["Desktop Chrome"] },
    },
  ],
  webServer: {
    command: "npm run dev:frontend",
    cwd: projectRoot,
    url: "http://localhost:5173",
    reuseExistingServer: true,
    timeout: 120000,
  },
});
