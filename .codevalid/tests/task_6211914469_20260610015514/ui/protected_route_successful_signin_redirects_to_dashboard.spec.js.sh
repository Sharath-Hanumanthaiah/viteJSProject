import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../helpers/execution-recorder.js";
import { setupSignInMocks } from "../helpers/mock-api.js";

test("Successful Sign In Redirects to Dashboard", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "protected_route_successful_signin_redirects_to_dashboard",
    testTitle: "Successful Sign In Redirects to Dashboard",
  });

  await recorder.step("Clear any existing session and register successful sign in plus protected-page API mocks", async () => {
    await page.goto("/signin");
    await page.evaluate(() => {
      localStorage.removeItem("user");
      localStorage.removeItem("token");
    });
    await setupSignInMocks(page, { signInScenario: "success", includeHomeApis: true });
  });

  await recorder.step("Navigate to the sign in page", async () => {
    await page.goto("/signin");
    await expect(page.getByRole("heading", { name: "Welcome Back" })).toBeVisible();
  });

  await recorder.step("Enter valid sign in credentials", async () => {
    await page.getByPlaceholder("john@example.com").fill("john@example.com");
    await page.getByPlaceholder("••••••••").fill("correctpassword");
  });

  await recorder.step("Submit the sign in form", async () => {
    await page.getByRole("button", { name: /sign in/i }).click();
  });

  await recorder.step("Verify the authenticated user is redirected to the protected home page and the dashboard content is rendered", async () => {
    await expect(page).toHaveURL(/\/$/);
    await expect(page.getByRole("heading", { name: "Registration Desk" })).toBeVisible();
    await expect(page.getByText("Select Active Event")).toBeVisible();
    await expect(page.getByText("Registered Audience")).toBeVisible();
  });

  console.log("CODEVALID_TEST_ASSERTION_OK:protected_route_successful_signin_redirects_to_dashboard");
  await recorder.save(testInfo);
});
