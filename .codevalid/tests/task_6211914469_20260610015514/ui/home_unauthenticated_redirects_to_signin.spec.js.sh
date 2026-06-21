import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../../../../ui_test/helpers/execution-recorder.js";
import { mockHomePageApis } from "../../../../../ui_test/helpers/mock-api.js";

test("Unauthenticated user accessing home redirects to sign in", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder("home_unauthenticated_redirects_to_signin", "Unauthenticated User Accessing Home Redirects to Sign In");

  await page.addInitScript(() => {
    localStorage.removeItem("user");
    localStorage.removeItem("token");
  });

  await recorder.recordStep("Clear any existing user session from localStorage");
  await mockHomePageApis(page);
  await recorder.recordStep("Register mocked home API routes to ensure no real backend calls occur");

  await page.goto("/");
  await recorder.recordStep("Navigate to protected home route '/'");

  await expect(page).toHaveURL(/\/signin$/);
  await expect(page.getByRole("heading", { name: "Welcome Back" })).toBeVisible();
  await expect(page.getByRole("heading", { name: "Registration Desk" })).toHaveCount(0);
  await recorder.recordStep("Verify browser redirects to '/signin' and protected Home content is not rendered");

  console.log("CODEVALID_TEST_ASSERTION_OK:home_unauthenticated_redirects_to_signin");
  await recorder.save(testInfo);
});
