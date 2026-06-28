/**
 * CodeValid Sample Test – Event Registration App
 *
 * Framework : React 19 + Vite + React-Router-DOM
 * Test runner: Playwright (chromium, headless)
 * Config    : .codevalid/ui/playwright.config.js
 *
 * Covers:
 *  1. Sign-in page renders and shows validation errors
 *  2. Successful sign-in navigates to the home / registration desk
 *  3. Home page displays mock events and the registration form
 *  4. Registering a new attendee appends them to the table
 *
 * All backend calls are intercepted via the mock-server helpers so no
 * live Express server is required during CI runs.
 */

import { test, expect } from "@playwright/test";
import { setupMockRoutes, injectUserSession } from "../mock/mock-server.js";
import { ExecutionRecorder } from "../helpers/execution-recorder.js";

// ---------------------------------------------------------------------------
// Test 1 – Sign-in page: renders correctly and enforces validation
// ---------------------------------------------------------------------------
test("sign-in page renders and validates required fields", async ({
  page,
}, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "CV-SAMPLE-001",
    testTitle: "sign-in page renders and validates required fields",
  });

  await setupMockRoutes(page);

  recorder.record("navigate to /signin");
  await page.goto("/signin");

  recorder.record("assert heading is visible");
  await expect(
    page.getByRole("heading", { name: /welcome back/i })
  ).toBeVisible();

  recorder.record("submit empty form to trigger validation");
  await page.getByRole("button", { name: /sign in/i }).click();

  recorder.record("assert email validation error");
  await expect(page.getByText(/email is required/i)).toBeVisible();

  recorder.record("assert password validation error");
  await expect(page.getByText(/password is required/i)).toBeVisible();

  recorder.record("fill invalid email format");
  await page.getByPlaceholder(/john@example\.com/i).fill("not-an-email");
  await page.getByRole("button", { name: /sign in/i }).click();

  recorder.record("assert invalid email error");
  await expect(page.getByText(/invalid email address/i)).toBeVisible();

  await recorder.save(testInfo);
});

// ---------------------------------------------------------------------------
// Test 2 – Successful sign-in redirects to home
// ---------------------------------------------------------------------------
test("successful sign-in redirects to registration desk", async ({
  page,
}, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "CV-SAMPLE-002",
    testTitle: "successful sign-in redirects to registration desk",
  });

  await setupMockRoutes(page);

  recorder.record("navigate to /signin");
  await page.goto("/signin");

  recorder.record("fill valid credentials");
  await page.getByPlaceholder(/john@example\.com/i).fill("testuser@example.com");
  await page.getByPlaceholder(/••••••••/i).fill("password123");

  recorder.record("click sign-in button");
  await page.getByRole("button", { name: /sign in/i }).click();

  recorder.record("assert redirect to home / registration desk");
  await expect(page).toHaveURL(/\/$/);
  await expect(
    page.getByRole("heading", { name: /registration desk/i })
  ).toBeVisible();

  await recorder.save(testInfo);
});

// ---------------------------------------------------------------------------
// Test 3 – Home page shows events and registration form when authenticated
// ---------------------------------------------------------------------------
test("home page shows events dropdown and registration form", async ({
  page,
}, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "CV-SAMPLE-003",
    testTitle: "home page shows events dropdown and registration form",
  });

  await setupMockRoutes(page);

  // Inject session before navigating so ProtectedRoute passes
  await page.goto("/");
  await injectUserSession(page);
  await page.goto("/");

  recorder.record("assert Registration Desk heading");
  await expect(
    page.getByRole("heading", { name: /registration desk/i })
  ).toBeVisible();

  recorder.record("assert event selector exists");
  const eventSelect = page.locator("select");
  await expect(eventSelect).toBeVisible();

  recorder.record("assert first event option is selected");
  await expect(eventSelect).toHaveValue("event_codevalid001");

  recorder.record("assert registration form inputs are visible");
  await expect(page.getByPlaceholder(/Jane Smith/i)).toBeVisible();
  await expect(page.getByPlaceholder(/jane@smith\.com/i)).toBeVisible();
  await expect(page.getByPlaceholder(/\+1 \(555\) 000-0000/i)).toBeVisible();

  await recorder.save(testInfo);
});

// ---------------------------------------------------------------------------
// Test 4 – Register a new attendee
// ---------------------------------------------------------------------------
test("registering a new attendee adds them to the table", async ({
  page,
}, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "CV-SAMPLE-004",
    testTitle: "registering a new attendee adds them to the table",
  });

  await setupMockRoutes(page);

  await page.goto("/");
  await injectUserSession(page);
  await page.goto("/");

  recorder.record("wait for registration form to be ready");
  await expect(page.getByPlaceholder(/Jane Smith/i)).toBeVisible();

  recorder.record("fill attendee details");
  await page.getByPlaceholder(/Jane Smith/i).fill("Charlie Brown");
  await page.getByPlaceholder(/jane@smith\.com/i).fill("charlie@example.com");
  await page.getByPlaceholder(/\+1 \(555\) 000-0000/i).fill("+1 (555) 200-0001");

  recorder.record("click Confirm Registration button");
  await page.getByRole("button", { name: /confirm registration/i }).click();

  recorder.record("assert success message");
  await expect(
    page.getByText(/attendee registered successfully/i)
  ).toBeVisible();

  recorder.record("assert new attendee appears in the table");
  await expect(page.getByText("Charlie Brown")).toBeVisible();

  await recorder.save(testInfo);
});
