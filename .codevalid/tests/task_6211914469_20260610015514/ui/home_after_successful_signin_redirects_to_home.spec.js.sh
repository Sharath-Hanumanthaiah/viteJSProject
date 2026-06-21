import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../../../../ui_test/helpers/execution-recorder.js";
import { setupSignInMocks } from "../../../../../ui_test/helpers/mock-api.js";

test("Successful sign in redirects to home", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder("home_after_successful_signin_redirects_to_home", "Successful Sign In Redirects to Home");

  await page.addInitScript(() => {
    localStorage.removeItem("user");
    localStorage.removeItem("token");
  });

  await setupSignInMocks(page, { signInScenario: "success", includeHomeApis: true });
  await recorder.recordStep("Register sign-in success mock and dependent Home API mocks");

  await page.goto("/signin");
  await recorder.recordStep("Navigate to '/signin'");

  await page.getByPlaceholder("john@example.com").fill("john@example.com");
  await recorder.recordStep("Enter valid credentials email");

  await page.getByPlaceholder("••••••••").fill("correctpassword");
  await recorder.recordStep("Enter valid credentials password");

  await page.getByRole("button", { name: /sign in/i }).click();
  await recorder.recordStep("Click 'Sign In'");

  await expect(page).toHaveURL(/\/$/);
  await expect(page.getByRole("heading", { name: "Registration Desk" })).toBeVisible();
  await expect(page.getByText("Registered Audience")).toBeVisible();

  await expect.poll(async () => page.evaluate(() => localStorage.getItem("token"))).toBe("simulated-jwt-token-for-user_test1");
  await recorder.recordStep("Verify application redirects to '/', Home renders, and auth token is stored");

  console.log("CODEVALID_TEST_ASSERTION_OK:home_after_successful_signin_redirects_to_home");
  await recorder.save(testInfo);
});
