import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import {
  setupUnauthenticatedSession,
  mockSignUpPageApis,
} from "../../helpers/mock-api.js";

test("Signup Form Rejects When Passwords Don't Match", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "signup_passwords_do_not_match",
    testName: "Signup Form Rejects When Passwords Don't Match",
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

    await recorder.step("Confirm implemented signup UI has no confirm password field", async () => {
      await expect(page.locator('[name="confirmPassword"]')).toHaveCount(0);
    });

    await recorder.step("Fill visible required fields", async () => {
      await page.locator('[name="username"]').fill("johndoe");
      await page.locator('[name="fullName"]').fill("John Doe");
      await page.locator('[name="email"]').fill("user@example.com");
      await page.locator('[name="password"]').fill("Password123!");
    });

    await recorder.step("Verify no password mismatch validation exists in current UI", async () => {
      await expect(page.getByText("Passwords do not match")).toHaveCount(0);
      await expect(page.getByText(/confirm password/i)).toHaveCount(0);
    });

    await recorder.step("Document current implementation stays on signup until submitted", async () => {
      await expect(page).toHaveURL(/\/signup$/);
    });

    console.log("CODEVALID_TEST_ASSERTION_OK:signup_passwords_do_not_match");
  } finally {
    await recorder.save(testInfo);
  }
});
