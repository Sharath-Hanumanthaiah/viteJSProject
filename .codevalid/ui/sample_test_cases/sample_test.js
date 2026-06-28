// Sample Playwright test for the Eminence Events Registration App
// Tests sign-in flow and basic home page functionality using mocked API routes

import { test, expect } from "@playwright/test";
import { setupMockRoutes, teardownMockRoutes } from "../mock/mock-server.js";
import { ExecutionRecorder } from "../helpers/execution-recorder.js";

// ─── Sign-In Page Tests ───────────────────────────────────────────────────────

test.describe("Sign-In Page", () => {
  test.beforeEach(async ({ page }) => {
    await setupMockRoutes(page);
  });

  test.afterEach(async ({ page }) => {
    await teardownMockRoutes(page);
  });

  test("CV-001: Sign-in page loads and displays form elements", async ({
    page,
  }, testInfo) => {
    const recorder = new ExecutionRecorder("CV-001", testInfo.title);

    await recorder.step("Navigate to sign-in page", async () => {
      await page.goto("/signin");
    });

    await recorder.step("Verify page title / heading is visible", async () => {
      await expect(page.getByText("Welcome Back")).toBeVisible();
    });

    await recorder.step("Verify email input is present", async () => {
      await expect(page.getByPlaceholder("john@example.com")).toBeVisible();
    });

    await recorder.step("Verify password input is present", async () => {
      await expect(page.getByPlaceholder("••••••••")).toBeVisible();
    });

    await recorder.step("Verify Sign In button is present", async () => {
      await expect(
        page.getByRole("button", { name: /sign in/i })
      ).toBeVisible();
    });

    await recorder.save(testInfo);
  });

  test("CV-002: Sign-in form shows validation errors for empty fields", async ({
    page,
  }, testInfo) => {
    const recorder = new ExecutionRecorder("CV-002", testInfo.title);

    await recorder.step("Navigate to sign-in page", async () => {
      await page.goto("/signin");
    });

    await recorder.step("Submit empty form", async () => {
      await page.getByRole("button", { name: /sign in/i }).click();
    });

    await recorder.step("Expect email required error", async () => {
      await expect(page.getByText("Email is required")).toBeVisible();
    });

    await recorder.step("Expect password required error", async () => {
      await expect(page.getByText("Password is required")).toBeVisible();
    });

    await recorder.save(testInfo);
  });

  test("CV-003: Successful sign-in redirects to home page", async ({
    page,
  }, testInfo) => {
    const recorder = new ExecutionRecorder("CV-003", testInfo.title);

    await recorder.step("Navigate to sign-in page", async () => {
      await page.goto("/signin");
    });

    await recorder.step("Fill in valid credentials", async () => {
      await page.getByPlaceholder("john@example.com").fill("test@example.com");
      await page.getByPlaceholder("••••••••").fill("password123");
    });

    await recorder.step("Submit sign-in form", async () => {
      await page.getByRole("button", { name: /sign in/i }).click();
    });

    await recorder.step("Verify redirect to home (registration desk)", async () => {
      await expect(page).toHaveURL("/");
      await expect(page.getByText("Registration Desk")).toBeVisible();
    });

    await recorder.save(testInfo);
  });

  test("CV-004: Invalid credentials show error message", async ({
    page,
  }, testInfo) => {
    const recorder = new ExecutionRecorder("CV-004", testInfo.title);

    await recorder.step("Navigate to sign-in page", async () => {
      await page.goto("/signin");
    });

    await recorder.step("Fill in wrong credentials", async () => {
      await page.getByPlaceholder("john@example.com").fill("wrong@email.com");
      await page.getByPlaceholder("••••••••").fill("wrongpassword");
    });

    await recorder.step("Submit form", async () => {
      await page.getByRole("button", { name: /sign in/i }).click();
    });

    await recorder.step("Verify error message appears", async () => {
      await expect(
        page.getByText(/invalid email or password/i)
      ).toBeVisible();
    });

    await recorder.save(testInfo);
  });
});

// ─── Home Page / Registration Desk Tests ─────────────────────────────────────

test.describe("Home Page - Registration Desk", () => {
  test.beforeEach(async ({ page }) => {
    await setupMockRoutes(page);

    // Sign in first so the protected route is accessible
    await page.goto("/signin");
    await page.getByPlaceholder("john@example.com").fill("test@example.com");
    await page.getByPlaceholder("••••••••").fill("password123");
    await page.getByRole("button", { name: /sign in/i }).click();
    await expect(page).toHaveURL("/");
  });

  test.afterEach(async ({ page }) => {
    await teardownMockRoutes(page);
  });

  test("CV-005: Home page loads events and shows Registration Desk", async ({
    page,
  }, testInfo) => {
    const recorder = new ExecutionRecorder("CV-005", testInfo.title);

    await recorder.step("Verify Registration Desk heading", async () => {
      await expect(page.getByText("Registration Desk")).toBeVisible();
    });

    await recorder.step("Verify event selector is visible", async () => {
      await expect(page.getByText("Select Active Event")).toBeVisible();
    });

    await recorder.step("Verify first event is loaded in dropdown", async () => {
      await expect(
        page.getByRole("option", { name: /Global Tech Summit 2026/i })
      ).toBeAttached();
    });

    await recorder.save(testInfo);
  });

  test("CV-006: Registration form shows active status for open event", async ({
    page,
  }, testInfo) => {
    const recorder = new ExecutionRecorder("CV-006", testInfo.title);

    await recorder.step("Verify Registration Active badge is shown", async () => {
      await expect(page.getByText("Registration Active")).toBeVisible();
    });

    await recorder.step("Verify form fields are enabled", async () => {
      const nameInput = page.getByPlaceholder("Jane Smith");
      await expect(nameInput).toBeEnabled();
    });

    await recorder.save(testInfo);
  });

  test("CV-007: Registered attendees table is visible with existing registrations", async ({
    page,
  }, testInfo) => {
    const recorder = new ExecutionRecorder("CV-007", testInfo.title);

    await recorder.step("Verify Registered Audience heading", async () => {
      await expect(page.getByText("Registered Audience")).toBeVisible();
    });

    await recorder.step("Verify Alice Vance is listed", async () => {
      await expect(page.getByText("Alice Vance")).toBeVisible();
    });

    await recorder.step("Verify Bob Builder is listed", async () => {
      await expect(page.getByText("Bob Builder")).toBeVisible();
    });

    await recorder.save(testInfo);
  });

  test("CV-008: Registering a new attendee shows success message", async ({
    page,
  }, testInfo) => {
    const recorder = new ExecutionRecorder("CV-008", testInfo.title);

    await recorder.step("Fill in attendee name", async () => {
      await page.getByPlaceholder("Jane Smith").fill("New Attendee");
    });

    await recorder.step("Fill in attendee email", async () => {
      await page.getByPlaceholder("jane@smith.com").fill("newattendee@test.com");
    });

    await recorder.step("Fill in attendee phone", async () => {
      await page.getByPlaceholder("+1 (555) 000-0000").fill("+1 (555) 777-8888");
    });

    await recorder.step("Submit registration form", async () => {
      await page.getByRole("button", { name: /confirm registration/i }).click();
    });

    await recorder.step("Verify success message", async () => {
      await expect(
        page.getByText(/attendee registered successfully/i)
      ).toBeVisible();
    });

    await recorder.save(testInfo);
  });
});
