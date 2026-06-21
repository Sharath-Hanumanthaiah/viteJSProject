import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../helpers/execution-recorder.js";
import { setupSignUpMocks, mockHomePageApis } from "../helpers/mock-api.js";

test("Successful User Signup with Valid Data", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder("signup_happy_path_valid_credentials", "Successful User Signup with Valid Data");

  await recorder.step("Set up signup success and post-auth home API mocks");
  await setupSignUpMocks(page, { signUpScenario: "success", includeHomeApis: true });

  await recorder.step("Navigate directly to /signup");
  await page.goto("/signup");

  await recorder.step("Fill required signup fields with valid values");
  await page.getByPlaceholder("johndoe").fill("janedoe");
  await page.getByPlaceholder("John Doe").fill("Jane Doe");
  await page.getByPlaceholder("john@example.com").fill("user@example.com");
  await page.getByPlaceholder("••••••••").fill("Password123!");
  await page.getByPlaceholder("+1 (555) 000-0000").fill("+1 (555) 000-0000");
  await page.getByPlaceholder("Acme Corp").fill("Acme Corp");

  await recorder.step("Submit the signup form");
  await page.getByRole("button", { name: /create account/i }).click();

  await recorder.step("Verify the user is authenticated and redirected to the protected home route");
  await expect(page).toHaveURL(/\/$/);
  await expect(page.getByText(/create an account/i)).not.toBeVisible();

  await recorder.step("Verify no client-side validation errors are displayed");
  await expect(page.getByText("Username is required")).not.toBeVisible();
  await expect(page.getByText("Full name is required")).not.toBeVisible();
  await expect(page.getByText("Email is required")).not.toBeVisible();
  await expect(page.getByText("Password is required")).not.toBeVisible();

  console.log("CODEVALID_TEST_ASSERTION_OK:signup_happy_path_valid_credentials");
  await recorder.save(testInfo);
});
