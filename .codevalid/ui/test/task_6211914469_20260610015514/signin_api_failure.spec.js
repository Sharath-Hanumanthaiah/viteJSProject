import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import {
  setupUnauthenticatedSession,
  mockSignInPageApis,
} from "../../helpers/mock-api.js";

test("Handle 500 internal server error during authentication", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "signin_api_failure",
    testTitle: "Handle 500 internal server error during authentication",
  });

  try {
    await recorder.step("Prepare unauthenticated session and server error route", async () => {
      await setupUnauthenticatedSession(page);
      await mockSignInPageApis(page);
      await page.route("**/api/auth/signin", async (route) => {
        await route.fulfill({
          status: 500,
          contentType: "application/json",
          body: JSON.stringify({
            message: "Authentication service unavailable. Please try again later.",
          }),
        });
      });
    });

    await recorder.step("Open the sign-in page", async () => {
      await page.goto("/signin");
      await expect(page.getByRole("heading", { name: "Welcome Back" })).toBeVisible();
    });

    await recorder.step("Enter valid credentials", async () => {
      await page.locator('[name="email"]').fill("testuser@example.com");
      await page.locator('[name="password"]').fill("Password123");
    });

    await recorder.step("Submit credentials and receive 500 error", async () => {
      await page.getByRole("button", { name: /^Sign In$/ }).click();
    });

    await recorder.step("Verify error message, retained form state, and retry availability", async () => {
      await expect(
        page.getByText("Authentication service unavailable. Please try again later.")
      ).toBeVisible();
      await expect(page).toHaveURL(/\/signin$/);
      await expect(page.locator('[name="email"]')).toHaveValue("testuser@example.com");
      await expect(page.locator('[name="password"]')).toHaveValue("Password123");
      await expect(page.getByRole("button", { name: /^Sign In$/ })).toBeEnabled();
      const token = await page.evaluate(() => localStorage.getItem("token"));
      expect(token).toBeNull();
    });

    console.log("CODEVALID_TEST_ASSERTION_OK:signin_api_failure");
  } finally {
    await recorder.save(testInfo);
  }
});
