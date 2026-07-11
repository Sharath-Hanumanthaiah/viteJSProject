import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import {
  setupUnauthenticatedSession,
  mockHomePageApis,
} from "../../helpers/mock-api.js";

test("Unauthenticated User Accessing Home Redirects to Sign In", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "home_unauthenticated_redirects_to_signin",
    testName: "Unauthenticated User Accessing Home Redirects to Sign In",
  });

  try {
    await recorder.step("Set unauthenticated browser session", async () => {
      await setupUnauthenticatedSession(page);
      await mockHomePageApis(page, { upcomingEvents: [] });
    });

    await recorder.step("Navigate to the protected home route", async () => {
      await page.goto("/");
    });

    await recorder.step("Verify redirect to the sign in page", async () => {
      await expect(page).toHaveURL(/\/signin$/);
      await expect(page.getByRole("heading", { name: "Welcome Back" })).toBeVisible();
      await expect(page.getByRole("button", { name: /sign in/i })).toBeVisible();
      await expect(page.getByRole("heading", { name: "Registration Desk" })).toHaveCount(0);
    });

    console.log("CODEVALID_TEST_ASSERTION_OK:home_unauthenticated_redirects_to_signin");
  } finally {
    await recorder.save(testInfo);
  }
});
