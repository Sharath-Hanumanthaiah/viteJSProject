import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import {
  setupUnauthenticatedSession,
  mockSignUpPageApis,
  mockSuccessfulSignupFlow,
} from "../../helpers/mock-api.js";

test("Successful User Signup with Valid Data", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "signup_happy_path_valid_credentials",
    testName: "Successful User Signup with Valid Data",
  });

  try {
    await recorder.step("Set unauthenticated session and register signup success mocks", async () => {
      await setupUnauthenticatedSession(page);
      await mockSignUpPageApis(page);
      await mockSuccessfulSignupFlow(page, {
        user: {
          id: "user-001",
          username: "johndoe",
          email: "user@example.com",
          fullName: "John Doe",
          organization: "Acme Corp",
        },
        token: "signup-token-123",
        events: [],
      });
    });

    await recorder.step("Navigate to the signup page", async () => {
      await page.goto("/signup");
    });

    await recorder.step("Verify signup page is rendered", async () => {
      await expect(page.getByRole("heading", { name: "Create an Account" })).toBeVisible();
    });

    await recorder.step("Fill the required signup fields with valid data", async () => {
      await page.locator('[name="username"]').fill("johndoe");
      await page.locator('[name="fullName"]').fill("John Doe");
      await page.locator('[name="email"]').fill("user@example.com");
      await page.locator('[name="password"]').fill("Password123!");
      await page.locator('[name="phone"]').fill("+1 (555) 000-0000");
      await page.locator('[name="organization"]').fill("Acme Corp");
    });

    await recorder.step("Submit the signup form", async () => {
      await page.getByRole("button", { name: /create account/i }).click();
    });

    await recorder.step("Verify redirect to authenticated home and persisted session", async () => {
      await expect(page).toHaveURL(/\/$/);
      await expect(page.getByRole("heading", { name: /event registration/i })).toBeVisible();
      await expect(page.getByText("Email is required")).toHaveCount(0);
      await expect(page.getByText("Password is required")).toHaveCount(0);
      await expect(page.getByText("Invalid email address")).toHaveCount(0);
      await expect.poll(() => page.evaluate(() => localStorage.getItem("token"))).toBe("signup-token-123");
    });

    console.log("CODEVALID_TEST_ASSERTION_OK:signup_happy_path_valid_credentials");
  } finally {
    await recorder.save(testInfo);
  }
});
