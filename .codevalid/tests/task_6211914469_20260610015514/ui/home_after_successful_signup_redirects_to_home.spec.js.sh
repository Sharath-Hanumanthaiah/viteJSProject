import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../../../../ui_test/helpers/execution-recorder.js";
import { loadMockApi, mockHomePageApis } from "../../../../../ui_test/helpers/mock-api.js";

test("Successful sign up redirects to home", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder("home_after_successful_signup_redirects_to_home", "Successful Sign Up Redirects to Home");
  const mockApi = loadMockApi();
  const signupScenario = mockApi["POST /api/auth/signup"]?.success;

  if (!signupScenario) {
    throw new Error("Required mock scenario missing: POST /api/auth/signup -> success");
  }

  await page.addInitScript(() => {
    localStorage.removeItem("user");
    localStorage.removeItem("token");
  });

  await page.route("**/api/auth/signup", async (route) => {
    if (route.request().method() !== "POST") {
      await route.continue();
      return;
    }

    await route.fulfill({
      status: signupScenario.output.status,
      contentType: "application/json",
      body: JSON.stringify(signupScenario.output.body),
    });
  });
  await mockHomePageApis(page);
  await recorder.recordStep("Register sign-up success mock and dependent Home API mocks");

  await page.goto("/signup");
  await recorder.recordStep("Navigate to '/signup'");

  await page.getByPlaceholder("johndoe").fill("janedoe");
  await recorder.recordStep("Enter username");

  await page.getByPlaceholder("John Doe").fill("Jane Doe");
  await recorder.recordStep("Enter full name");

  await page.getByPlaceholder("john@example.com").fill("jane@example.com");
  await recorder.recordStep("Enter email address");

  await page.getByPlaceholder("••••••••").fill("secure123");
  await recorder.recordStep("Enter password");

  await page.getByPlaceholder("+1 (555) 000-0000").fill("+1 (555) 000-0000");
  await recorder.recordStep("Enter phone number");

  await page.getByPlaceholder("Acme Corp").fill("Acme Corp");
  await recorder.recordStep("Enter organization");

  await page.getByRole("button", { name: /create account/i }).click();
  await recorder.recordStep("Click 'Create Account'");

  await expect(page).toHaveURL(/\/$/);
  await expect(page.getByRole("heading", { name: "Registration Desk" })).toBeVisible();
  await expect(page.getByText("Registered Audience")).toBeVisible();

  await expect.poll(async () => page.evaluate(() => localStorage.getItem("token"))).toBe("simulated-jwt-token-for-user_signup1");
  await recorder.recordStep("Verify application redirects to '/', Home renders, and auth token is stored after signup");

  console.log("CODEVALID_TEST_ASSERTION_OK:home_after_successful_signup_redirects_to_home");
  await recorder.save(testInfo);
});
