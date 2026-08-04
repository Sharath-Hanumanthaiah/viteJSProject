import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import {
  setupUnauthenticatedSession,
  mockSignInPageApis,
} from "../../helpers/mock-api.js";

test("Submit empty email and password", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "signin_empty_fields_submission",
    testTitle: "Submit empty email and password",
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

    await recorder.step("Submit the form with empty email and password", async () => {
      await page.getByRole("button", { name: /^Sign In$/ }).click();
    });

    await recorder.step("Verify client-side validation prevents submission", async () => {
      await expect(page.getByText("Email is required")).toBeVisible();
      await expect(page.getByText("Password is required")).toBeVisible();
      await expect(page.locator('[name="email"]')).toHaveValue("");
      await expect(page.locator('[name="password"]')).toHaveValue("");
      await expect(page).toHaveURL(/\/signin$/);
      expect(signinRequestCount).toBe(0);
      await expect(page.getByRole("button", { name: /^Sign In$/ })).toBeEnabled();
    });

    console.log("CODEVALID_TEST_ASSERTION_OK:signin_empty_fields_submission");
  } finally {
    await recorder.save(testInfo);
  }
});
