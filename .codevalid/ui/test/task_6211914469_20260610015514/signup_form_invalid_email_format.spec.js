import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import {
  setupUnauthenticatedSession,
  mockSignUpPageApis,
} from "../../helpers/mock-api.js";

test("Signup form shows validation error for improperly formatted email", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "signup_form_invalid_email_format",
    testTitle: "Signup form shows validation error for improperly formatted email",
  });

  try {
    let signupRequestCount = 0;

    await recorder.step("Prepare signup page with API call tracking", async () => {
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

    await recorder.step("Open signup page and enter invalid email", async () => {
      await page.goto("/signup");
      await page.locator('[name="username"]').fill("john_doe");
      await page.locator('[name="fullName"]').fill("John Doe");
      await page.locator('[name="password"]').fill("Password123!");
      await page.locator('[name="email"]').fill("invalid-email");
    });

    await recorder.step("Attempt form submission", async () => {
      await page.getByRole("button", { name: /create account/i }).click();
    });

    await recorder.step("Verify invalid email message and no API request", async () => {
      await expect(page).toHaveURL(/\/signup$/);
      await expect(page.getByText("Invalid email address")).toBeVisible();
      await expect(page.locator('[name="email"]')).toHaveValue("invalid-email");
      expect(signupRequestCount).toBe(0);
    });

    console.log("CODEVALID_TEST_ASSERTION_OK:signup_form_invalid_email_format");
  } finally {
    await recorder.save(testInfo);
  }
});
