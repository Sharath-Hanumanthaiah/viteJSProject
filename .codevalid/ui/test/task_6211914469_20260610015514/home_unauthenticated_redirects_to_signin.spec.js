import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../../helpers/execution-recorder.js";
import {
  setupUnauthenticatedSession,
  mockProtectedHomePageApis,
} from "../../../helpers/mock-api.js";

test("Unauthenticated User Accessing Home Redirects to Sign In", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "home_unauthenticated_redirects_to_signin",
    testTitle: "Unauthenticated User Accessing Home Redirects to Sign In",
  });

  await recorder.step("Set up unauthenticated browser session", async () => {
    await setupUnauthenticatedSession(page);
    await mockProtectedHomePageApis(page, { events: [] });
  });

  await recorder.step("Navigate to protected home route '/'", async () => {
    await page.goto("/");
  });

  await recorder.step("Verify browser redirects to '/signin' and home content is not rendered", async () => {
    await expect(page).toHaveURL(/\/signin$/);
    await expect(page.getByRole("heading", { name: "Welcome Back" })).toBeVisible();
    await expect(page.getByRole("heading", { name: "Registration Desk" })).toHaveCount(0);
  });

  console.log("CODEVALID_TEST_ASSERTION_OK:home_unauthenticated_redirects_to_signin");
  await recorder.save(testInfo);
});
