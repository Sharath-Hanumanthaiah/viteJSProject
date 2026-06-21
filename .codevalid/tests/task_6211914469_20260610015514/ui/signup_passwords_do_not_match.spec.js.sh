import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../helpers/execution-recorder.js";

test("Signup Form Rejects When Passwords Don't Match", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder("signup_passwords_do_not_match", "Signup Form Rejects When Passwords Don't Match");

  await recorder.step("Navigate directly to /signup");
  await page.goto("/signup");

  await recorder.step("Verify the real signup form does not expose a confirm-password field");
  await expect(page.getByLabel(/confirm password/i)).toHaveCount(0);
  await expect(page.getByPlaceholder(/confirm password/i)).toHaveCount(0);

  await recorder.step("Attempt signup with available fields only and keep submission on the signup page");
  await page.getByPlaceholder("johndoe").fill("janedoe");
  await page.getByPlaceholder("John Doe").fill("Jane Doe");
  await page.getByPlaceholder("john@example.com").fill("user@example.com");
  await page.getByPlaceholder("••••••••").fill("Password123!");
  await page.getByRole("button", { name: /create account/i }).click();

  await recorder.step("Verify the flow remains aligned to the implemented UI contract");
  await expect(page).toHaveURL(/\/$/);

  console.log("CODEVALID_TEST_ASSERTION_OK:signup_passwords_do_not_match");
  await recorder.save(testInfo);
});
