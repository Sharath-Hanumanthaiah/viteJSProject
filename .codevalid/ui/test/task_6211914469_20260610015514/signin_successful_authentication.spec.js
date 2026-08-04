import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import {
  setupUnauthenticatedSession,
  mockSignInPageApis,
  mockSuccessfulSigninFlow,
  mockProtectedHomePageApis,
} from "../../helpers/mock-api.js";
import { mockUser, mockToken, mockEvents } from "../../mock/mock-data.js";

test("Submit valid credentials and redirect to dashboard", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "signin_successful_authentication",
    testTitle: "Submit valid credentials and redirect to dashboard",
  });

  try {
    await recorder.step("Prepare unauthenticated session and successful signin mocks", async () => {
      await setupUnauthenticatedSession(page);
      await mockSignInPageApis(page);
      await mockSuccessfulSigninFlow(page, {
        user: mockUser,
        token: mockToken,
        events: mockEvents,
      });
      await mockProtectedHomePageApis(page, { events: mockEvents });
    });

    await recorder.step("Open the sign-in page", async () => {
      await page.goto("/signin");
      await expect(page.getByRole("heading", { name: "Welcome Back" })).toBeVisible();
    });

    await recorder.step("Enter valid credentials", async () => {
      await page.locator('[name="email"]').fill(mockUser.email);
      await page.locator('[name="password"]').fill("Password123");
    });

    await recorder.step("Submit valid credentials", async () => {
      await page.getByRole("button", { name: /^Sign In$/ }).click();
    });

    await recorder.step("Verify redirect to dashboard and persisted auth state", async () => {
      await expect(page).toHaveURL(/\/$/);
      await expect(page.getByRole("heading", { name: /upcoming events/i })).toBeVisible();
      await expect(page.getByRole("heading", { name: "Welcome Back" })).toHaveCount(0);

      const session = await page.evaluate(() => ({
        token: localStorage.getItem("token"),
        user: localStorage.getItem("user"),
      }));

      expect(session.token).toBe(mockToken);
      expect(session.user).toContain(mockUser.email);
    });

    console.log("CODEVALID_TEST_ASSERTION_OK:signin_successful_authentication");
  } finally {
    await recorder.save(testInfo);
  }
});
