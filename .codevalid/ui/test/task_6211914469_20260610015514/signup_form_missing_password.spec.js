import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import {
  setupUnauthenticatedSession,
  mockSignUpPageApis,
} from "../../helpers/mock-api.js";

test("Signup form prevents submission when password is missing", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "signup_form_missing_password",
    testTitle: "Signup form prevents submission when password is missing",
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

    await recorder.step("Fill required fields except password", async () => {
      await page.locator('[name="username"]').fill("john_doe");
      await page.locator('[name="fullName"]').fill("John Doe");
      await page.locator('[name="email"]').fill("john@example.com");
      await expect(page.locator('[name="password"]')).toHaveValue("");
    });

    await recorder.step("Attempt to submit signup form", async () => {
      await page.getByRole("button", { name: /create account/i }).click();
    });

    await recorder.step("Verify password required validation and no API request", async () => {
      await expect(page).toHaveURL(/\/signup$/);
      await expect(page.getByText("Password is required")).toBeVisible();
      await expect(page.locator('[name="password"]')).toHaveValue("");
      expect(signupRequestCount).toBe(0);
    });

    console.log("CODEVALID_TEST_ASSERTION_OK:signup_form_missing_password");
  } finally {
    await recorder.save(testInfo);
  }
});
