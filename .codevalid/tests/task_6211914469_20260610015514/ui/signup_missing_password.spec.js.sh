import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../helpers/execution-recorder.js";

test("Signup Form Rejects When Password Is Missing", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder("signup_missing_password", "Signup Form Rejects When Password Is Missing");

  await recorder.step("Navigate directly to /signup");
  await page.goto("/signup");

  await recorder.step("Fill required fields except password");
  await page.getByPlaceholder("johndoe").fill("janedoe");
  await page.getByPlaceholder("John Doe").fill("Jane Doe");
  await page.getByPlaceholder("john@example.com").fill("user@example.com");

  await recorder.step("Submit the signup form");
  await page.getByRole("button", { name: /create account/i }).click();

  await recorder.step("Verify submission is blocked and password validation appears");
  await expect(page).toHaveURL(/\/signup$/);
  await expect(page.getByText("Password is required")).toBeVisible();

  console.log("CODEVALID_TEST_ASSERTION_OK:signup_missing_password");
  await recorder.save(testInfo);
});
