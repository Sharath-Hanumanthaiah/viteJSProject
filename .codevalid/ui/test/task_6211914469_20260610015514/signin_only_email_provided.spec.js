import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import {
  setupUnauthenticatedSession,
  mockSignInPageApis,
} from "../../helpers/mock-api.js";

test("Submit with only email provided", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "signin_only_email_provided",
    testTitle: "Submit with only email provided",
  });

  let signinRequestCount = 0;

  try {
    await recorder.step("Register request observer for unexpected signin submission", async () => {
      await page.route("**/api/auth/signin", async (route) => {
        signinRequestCount += 1;
        await route.fulfill({
          status: 500,
          contentType: "application/json",
          body: JSON.stringify({ message: "Unexpected signin request" }),
        });
      });
    });

    await recorder.step("Prepare unauthenticated session and sign-in page mocks", async () => {
      await setupUnauthenticatedSession(page);
      await mockSignInPageApis(page);
    });

    await recorder.step("Open the sign-in page", async () => {
      await page.goto("/signin");
      await expect(page.getByRole("heading", { name: "Welcome Back" })).toBeVisible();
    });

    await recorder.step("Enter only the email field", async () => {
      await page.locator('[name="email"]').fill("testuser@example.com");
      await expect(page.locator('[name="email"]')).toHaveValue("testuser@example.com");
      await expect(page.locator('[name="password"]')).toHaveValue("");
    });

    await recorder.step("Submit with password left empty", async () => {
      await page.getByRole("button", { name: /^Sign In$/ }).click();
    });

    await recorder.step("Verify password validation blocks API submission", async () => {
      await expect(page.getByText("Password is required")).toBeVisible();
      await expect(page).toHaveURL(/\/signin$/);
      expect(signinRequestCount).toBe(0);
    });

    console.log("CODEVALID_TEST_ASSERTION_OK:signin_only_email_provided");
  } finally {
    await recorder.save(testInfo);
  }
});
