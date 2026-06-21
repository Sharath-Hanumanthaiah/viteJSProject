import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../helpers/execution-recorder.js";

test("Signup Form Rejects When Email Is Missing", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder("signup_missing_email", "Signup Form Rejects When Email Is Missing");

  await recorder.step("Navigate directly to /signup");
  await page.goto("/signup");

  await recorder.step("Fill all required fields except email");
  await page.getByPlaceholder("johndoe").fill("janedoe");
  await page.getByPlaceholder("John Doe").fill("Jane Doe");
  await page.getByPlaceholder("••••••••").fill("Password123!");

  await recorder.step("Submit the signup form");
  await page.getByRole("button", { name: /create account/i }).click();

  await recorder.step("Verify submission is blocked and email validation appears");
  await expect(page).toHaveURL(/\/signup$/);
  await expect(page.getByText("Email is required")).toBeVisible();

  console.log("CODEVALID_TEST_ASSERTION_OK:signup_missing_email");
  await recorder.save(testInfo);
});
