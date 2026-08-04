import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import {
  setupUnauthenticatedSession,
  mockSignInPageApis,
  mockFailedSigninFlow,
} from "../../helpers/mock-api.js";

test("Submit with valid email and wrong password", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "signin_invalid_credentials",
    testTitle: "Submit with valid email and wrong password",
  });

  try {
    await recorder.step("Prepare unauthenticated session and failed signin mock", async () => {
      await setupUnauthenticatedSession(page);
      await mockSignInPageApis(page);
      await mockFailedSigninFlow(page, {
        message: "Invalid email or password.",
      });
    });

    await recorder.step("Open the sign-in page", async () => {
      await page.goto("/signin");
      await expect(page.getByRole("heading", { name: "Welcome Back" })).toBeVisible();
    });

    await recorder.step("Enter valid email and incorrect password", async () => {
      await page.locator('[name="email"]').fill("testuser@example.com");
      await page.locator('[name="password"]').fill("WrongPassword123");
    });

    await recorder.step("Submit invalid credentials", async () => {
      await page.getByRole("button", { name: /^Sign In$/ }).click();
    });

    await recorder.step("Verify authentication error and no redirect", async () => {
      await expect(page.getByText("Invalid email or password.")).toBeVisible();
      await expect(page).toHaveURL(/\/signin$/);
      await expect(page.locator('[name="email"]')).toHaveValue("testuser@example.com");
      await expect(page.locator('[name="password"]')).toHaveValue("WrongPassword123");
      const token = await page.evaluate(() => localStorage.getItem("token"));
      expect(token).toBeNull();
    });

    console.log("CODEVALID_TEST_ASSERTION_OK:signin_invalid_credentials");
  } finally {
    await recorder.save(testInfo);
  }
});
