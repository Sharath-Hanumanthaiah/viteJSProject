/**
 * sample_test.js
 *
 * Sample Playwright test suite for the Event-Registration SPA.
 * Stack: React 19 + Vite + React Router + Tailwind CSS
 * Backend: Express REST API (intercepted via Playwright route mocks)
 *
 * Covers:
 *  1. Sign-in page renders correctly
 *  2. Sign-in with valid credentials redirects to home
 *  3. Sign-in with invalid credentials shows error
 *  4. Home page loads events list after sign-in
 *  5. Registration form submits successfully for an active event
 */

import { test, expect } from "@playwright/test";
import { setupApiMocks, teardownApiMocks } from "../mocks/mock-server.js";
import { ExecutionRecorder } from "../helpers/execution-recorder.js";

// ─── helpers ──────────────────────────────────────────────────────────────────

/**
 * Inject a localStorage session so tests that need an authenticated state
 * can skip the full sign-in flow.
 */
async function injectAuthSession(page) {
  await page.addInitScript(() => {
    const user = {
      id: "user_1",
      username: "johndoe",
      email: "john@example.com",
      fullName: "John Doe",
    };
    localStorage.setItem("user", JSON.stringify(user));
    localStorage.setItem("token", "simulated-jwt-token-for-user_1");
  });
}

// ─── test suite ───────────────────────────────────────────────────────────────

test.describe("Sign-In Page", () => {
  test.beforeEach(async ({ page }) => {
    await setupApiMocks(page);
  });

  test.afterEach(async ({ page }) => {
    await teardownApiMocks(page);
  });

  test("CV-001 | sign-in page renders key UI elements", async ({ page }, testInfo) => {
    const recorder = new ExecutionRecorder("CV-001", testInfo.title);

    await recorder.step("Navigate to /signin", async () => {
      await page.goto("/signin");
    });

    await recorder.step("Assert heading is visible", async () => {
      await expect(page.getByRole("heading", { name: /welcome back/i })).toBeVisible();
    });

    await recorder.step("Assert email input is visible", async () => {
      await expect(page.getByPlaceholder("john@example.com")).toBeVisible();
    });

    await recorder.step("Assert password input is visible", async () => {
      await expect(page.getByPlaceholder("••••••••")).toBeVisible();
    });

    await recorder.step("Assert submit button is visible", async () => {
      await expect(page.getByRole("button", { name: /sign in/i })).toBeVisible();
    });

    await recorder.save(testInfo);
  });

  test("CV-002 | valid credentials redirect to home page", async ({ page }, testInfo) => {
    const recorder = new ExecutionRecorder("CV-002", testInfo.title);

    await recorder.step("Navigate to /signin", async () => {
      await page.goto("/signin");
    });

    await recorder.step("Fill email", async () => {
      await page.getByPlaceholder("john@example.com").fill("john@example.com");
    });

    await recorder.step("Fill password", async () => {
      await page.getByPlaceholder("••••••••").fill("password123");
    });

    await recorder.step("Submit form", async () => {
      await page.getByRole("button", { name: /sign in/i }).click();
    });

    await recorder.step("Assert redirected to home", async () => {
      await expect(page).toHaveURL("/");
    });

    await recorder.save(testInfo);
  });

  test("CV-003 | invalid credentials show error message", async ({ page }, testInfo) => {
    const recorder = new ExecutionRecorder("CV-003", testInfo.title);

    await recorder.step("Navigate to /signin", async () => {
      await page.goto("/signin");
    });

    await recorder.step("Fill invalid email", async () => {
      await page.getByPlaceholder("john@example.com").fill("nobody@nowhere.com");
    });

    await recorder.step("Fill wrong password", async () => {
      await page.getByPlaceholder("••••••••").fill("wrongpass");
    });

    await recorder.step("Submit form", async () => {
      await page.getByRole("button", { name: /sign in/i }).click();
    });

    await recorder.step("Assert error message is visible", async () => {
      await expect(
        page.getByText(/invalid email or password/i)
      ).toBeVisible();
    });

    await recorder.save(testInfo);
  });
});

test.describe("Home Page (authenticated)", () => {
  test.beforeEach(async ({ page }) => {
    await setupApiMocks(page);
    await injectAuthSession(page);
  });

  test.afterEach(async ({ page }) => {
    await teardownApiMocks(page);
  });

  test("CV-004 | home page loads and shows event selector", async ({ page }, testInfo) => {
    const recorder = new ExecutionRecorder("CV-004", testInfo.title);

    await recorder.step("Navigate to home", async () => {
      await page.goto("/");
    });

    await recorder.step("Assert Registration Desk heading", async () => {
      await expect(page.getByText("Registration Desk")).toBeVisible();
    });

    await recorder.step("Assert event dropdown is present", async () => {
      const select = page.locator("select");
      await expect(select).toBeVisible();
    });

    await recorder.step("Assert mock event title is in dropdown", async () => {
      await expect(
        page.locator("select option", { hasText: "Global Tech Summit 2026" })
      ).toBeAttached();
    });

    await recorder.save(testInfo);
  });

  test("CV-005 | registration form submits for an active event", async ({ page }, testInfo) => {
    const recorder = new ExecutionRecorder("CV-005", testInfo.title);

    await recorder.step("Navigate to home", async () => {
      await page.goto("/");
    });

    // Global Tech Summit 2026 is active (started 2 days ago, ends in 5 days)
    await recorder.step("Select active event", async () => {
      await page.locator("select").selectOption({ label: "Global Tech Summit 2026" });
    });

    await recorder.step("Fill attendee name", async () => {
      await page.getByPlaceholder("Jane Smith").fill("Test Attendee");
    });

    await recorder.step("Fill attendee email", async () => {
      await page.getByPlaceholder("jane@smith.com").fill("attendee@test.com");
    });

    await recorder.step("Fill attendee phone", async () => {
      await page.getByPlaceholder("+1 (555) 000-0000").fill("+1 (555) 999-8888");
    });

    await recorder.step("Submit registration", async () => {
      await page.getByRole("button", { name: /confirm registration/i }).click();
    });

    await recorder.step("Assert success message", async () => {
      await expect(
        page.getByText(/attendee registered successfully/i)
      ).toBeVisible();
    });

    await recorder.save(testInfo);
  });
});
