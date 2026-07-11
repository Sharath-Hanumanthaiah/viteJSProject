import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import {
  setupUnauthenticatedSession,
  mockHomePageApis,
} from "../../helpers/mock-api.js";

test("Unauthenticated User Accessing Home Redirects to Sign Up", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "home_unauthenticated_redirects_to_signup",
    testName: "Unauthenticated User Accessing Home Redirects to Sign Up",
  });

  try {
    await recorder.step("Set unauthenticated browser session", async () => {
      await setupUnauthenticatedSession(page);
      await mockHomePageApis(page, { upcomingEvents: [] });
    });

    await recorder.step("Navigate to the protected home route", async () => {
      await page.goto("/");
    });

    await recorder.step("Verify redirect to the sign up page in alternate routing configuration", async () => {
      await expect(page).toHaveURL(/\/signup$/);
      await expect(page.getByRole("heading", { name: "Create an Account" })).toBeVisible();
      await expect(page.getByRole("button", { name: /create account/i })).toBeVisible();
      await expect(page.getByRole("heading", { name: "Registration Desk" })).toHaveCount(0);
    });

    console.log("CODEVALID_TEST_ASSERTION_OK:home_unauthenticated_redirects_to_signup");
  } finally {
    await recorder.save(testInfo);
  }
});
