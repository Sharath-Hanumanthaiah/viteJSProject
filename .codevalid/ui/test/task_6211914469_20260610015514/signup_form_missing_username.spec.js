import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import {
  setupUnauthenticatedSession,
  mockSignUpPageApis,
} from "../../helpers/mock-api.js";

test("Signup form prevents submission when username is missing", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "signup_form_missing_username",
    testTitle: "Signup form prevents submission when username is missing",
  });

  try {
    let signupRequestCount = 0;

    await recorder.step("Prepare unauthenticated signup page with API call tracking", async () => {
      await setupUnauthenticatedSession(page);
      await mockSignUpPageApis(page);
      await page.route("**/api/auth/signup", async (route) => {
        signupRequestCount += 1;
        await route.fulfill({
          status: 500,
          contentType: "application/json",
          body: JSON.stringify({ message: "This route should not be reached." }),
        });
      });
    });

    await recorder.step("Open signup page", async () => {
      await page.goto("/signup");
      await expect(page.getByRole("heading", { name: "Create an Account" })).toBeVisible();
    });

    await recorder.step("Leave username empty and fill remaining required fields", async () => {
      await page.locator('[name="fullName"]').fill("John Doe");
      await page.locator('[name="email"]').fill("john@example.com");
      await page.locator('[name="password"]').fill("Password123!");
      await expect(page.locator('[name="username"]')).toHaveValue("");
    });

    await recorder.step("Attempt to submit signup form", async () => {
      await page.getByRole("button", { name: /create account/i }).click();
    });

    await recorder.step("Verify validation message and no API request", async () => {
      await expect(page).toHaveURL(/\/signup$/);
      await expect(page.getByText("Username is required")).toBeVisible();
      await expect(page.locator('[name="username"]')).toHaveValue("");
      expect(signupRequestCount).toBe(0);
    });

    console.log("CODEVALID_TEST_ASSERTION_OK:signup_form_missing_username");
  } finally {
    await recorder.save(testInfo);
  }
});
