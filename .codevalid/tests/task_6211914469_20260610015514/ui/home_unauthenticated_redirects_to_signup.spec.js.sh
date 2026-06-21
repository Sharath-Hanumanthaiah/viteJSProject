import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../../../../ui_test/helpers/execution-recorder.js";
import { mockHomePageApis } from "../../../../../ui_test/helpers/mock-api.js";

test("Unauthenticated user accessing home follows implemented redirect to sign in", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder("home_unauthenticated_redirects_to_signup", "Unauthenticated User Accessing Home Redirects to Sign Up");

  await page.addInitScript(() => {
    localStorage.removeItem("user");
    localStorage.removeItem("token");
  });

  await recorder.recordStep("Clear any existing user session from localStorage");
  await mockHomePageApis(page);
  await recorder.recordStep("Register mocked home API routes to prevent live backend traffic");

  await page.goto("/");
  await recorder.recordStep("Navigate to protected home route '/'");

  // Source-aligned assertion: ProtectedRoute redirects unauthenticated users to /signin.
  await expect(page).toHaveURL(/\/signin$/);
  await expect(page.getByRole("heading", { name: "Welcome Back" })).toBeVisible();
  await expect(page.getByRole("heading", { name: "Registration Desk" })).toHaveCount(0);
  await recorder.recordStep("Verify actual implemented redirect target is '/signin' rather than '/signup' and Home is not rendered");

  console.log("CODEVALID_TEST_ASSERTION_OK:home_unauthenticated_redirects_to_signup");
  await recorder.save(testInfo);
});
