import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../helpers/execution-recorder.js";

test("Signup Form Rejects Invalid Email Format", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder("signup_invalid_email_format", "Signup Form Rejects Invalid Email Format");

  await recorder.step("Navigate directly to /signup");
  await page.goto("/signup");

  await recorder.step("Fill required fields with an invalid email format");
  await page.getByPlaceholder("johndoe").fill("janedoe");
  await page.getByPlaceholder("John Doe").fill("Jane Doe");
  await page.getByPlaceholder("john@example.com").fill("invalid-email");
  await page.getByPlaceholder("••••••••").fill("Password123!");

  await recorder.step("Submit the signup form");
  await page.getByRole("button", { name: /create account/i }).click();

  await recorder.step("Verify submission is blocked and invalid email validation appears");
  await expect(page).toHaveURL(/\/signup$/);
  await expect(page.getByText("Invalid email address")).toBeVisible();

  console.log("CODEVALID_TEST_ASSERTION_OK:signup_invalid_email_format");
  await recorder.save(testInfo);
});
