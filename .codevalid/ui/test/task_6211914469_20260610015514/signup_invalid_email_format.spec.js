import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import {
  setupUnauthenticatedSession,
  mockSignUpPageApis,
} from "../../helpers/mock-api.js";

test("Signup Form Rejects Invalid Email Format", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "signup_invalid_email_format",
    testName: "Signup Form Rejects Invalid Email Format",
  });

  try {
    await recorder.step("Set unauthenticated session and page mocks", async () => {
      await setupUnauthenticatedSession(page);
      await mockSignUpPageApis(page);
    });

    await recorder.step("Navigate to the signup page", async () => {
      await page.goto("/signup");
    });

    await recorder.step("Verify signup page is rendered", async () => {
      await expect(page.getByRole("heading", { name: "Create an Account" })).toBeVisible();
    });

    await recorder.step("Fill required fields with an invalid email format", async () => {
      await page.locator('[name="username"]').fill("johndoe");
      await page.locator('[name="fullName"]').fill("John Doe");
      await page.locator('[name="email"]').fill("invalid-email");
      await page.locator('[name="password"]').fill("Password123!");
    });

    await recorder.step("Submit the signup form", async () => {
      await page.getByRole("button", { name: /create account/i }).click();
    });

    await recorder.step("Verify invalid email validation blocks submission", async () => {
      await expect(page).toHaveURL(/\/signup$/);
      await expect(page.getByText("Invalid email address")).toBeVisible();
      await expect(page.locator('[name="email"]')).toHaveValue("invalid-email");
      await expect.poll(() => page.evaluate(() => localStorage.getItem("token"))).toBeNull();
    });

    console.log("CODEVALID_TEST_ASSERTION_OK:signup_invalid_email_format");
  } finally {
    await recorder.save(testInfo);
  }
});
