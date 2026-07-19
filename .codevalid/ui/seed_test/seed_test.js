/**
 * Seed test – verifies the Vite/React app is reachable and renders
 * the expected page title and key UI landmark.
 *
 * This test intentionally has NO mock data of its own.
 * All API interception is handled in .codevalid/ui/mock/mock-server.js
 * using the fixture data from .codevalid/ui/mock/mock-data.js.
 *
 * Run with:
 *   npx playwright test --config .codevalid/ui/playwright.config.js --reporter=json
 */

import { test, expect } from "@playwright/test";
import { setupMockRoutes } from "../mock/mock-server.js";

test.describe("Seed – App reachability", () => {
  test.beforeEach(async ({ page }) => {
    // Intercept all API calls so the test never needs a live backend.
    await setupMockRoutes(page);
  });

  test("seed-app-reachable - app loads and shows the Sign In page title", async ({
    page,
  }) => {
    // Navigate to the sign-in page (a public route that requires no auth).
    await page.goto("/signin");

    // 1. The browser-tab title must match the app's HTML <title>.
    await expect(page).toHaveTitle(/eminence hub/i);

    // 2. The "Welcome Back" heading must be visible – confirms React rendered.
    await expect(
      page.getByRole("heading", { name: /welcome back/i })
    ).toBeVisible();

    // 3. The sign-in form fields must be present – confirms routing works.
    await expect(page.locator('input[name="email"]')).toBeVisible();
    await expect(page.locator('input[name="password"]')).toBeVisible();
  });
});
