import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../../../../ui_test/helpers/execution-recorder.js";
import { setupSignInMocks } from "../../../../../ui_test/helpers/mock-api.js";

test("Authenticated user directly accesses home page", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder("home_authenticated_user_accesses_home_directly", "Authenticated User Directly Accesses Home Page");

  await page.addInitScript(() => {
    localStorage.removeItem("user");
    localStorage.removeItem("token");
  });

  await setupSignInMocks(page, { signInScenario: "success", includeHomeApis: true });
  await recorder.recordStep("Register sign-in and home page API mocks");

  await page.goto("/signin");
  await recorder.recordStep("Navigate to '/signin'");

  await page.getByPlaceholder("john@example.com").fill("john@example.com");
  await recorder.recordStep("Enter valid email address");

  await page.getByPlaceholder("••••••••").fill("correctpassword");
  await recorder.recordStep("Enter valid password");

  await page.getByRole("button", { name: /sign in/i }).click();
  await recorder.recordStep("Submit the sign-in form");

  await expect(page).toHaveURL(/\/$/);
  await expect(page.getByRole("heading", { name: "Registration Desk" })).toBeVisible();
  await recorder.recordStep("Verify successful authentication redirects user to '/' and Home renders");

  await page.goto("/");
  await recorder.recordStep("Navigate again directly to '/' while authenticated");

  await expect(page).toHaveURL(/\/$/);
  await expect(page.getByRole("heading", { name: "Registration Desk" })).toBeVisible();
  await expect(page.getByText("Registered Audience")).toBeVisible();
  await recorder.recordStep("Verify authenticated user remains on Home without redirection");

  console.log("CODEVALID_TEST_ASSERTION_OK:home_authenticated_user_accesses_home_directly");
  await recorder.save(testInfo);
});
