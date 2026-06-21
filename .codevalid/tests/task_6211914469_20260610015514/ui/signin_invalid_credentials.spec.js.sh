import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../helpers/execution-recorder.js";

test("Sign In Fails With Valid Format But Invalid Credentials", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder("signin_invalid_credentials", "Sign In Fails With Valid Format But Invalid Credentials");

  await page.route("**/api/auth/signin", async (route) => {
    await route.fulfill({
      status: 401,
      contentType: "application/json",
      body: JSON.stringify({ message: "Invalid email or password." })
    });
  });

  try {
    await recorder.step("Navigate to /signin");
    await page.goto("/signin");
    await expect(page).toHaveURL(/\/signin$/);

    await recorder.step("Enter invalid email and password with valid format");
    await page.getByLabel("Email Address").fill("invalid@example.com");
    await page.getByLabel("Password").fill("WrongPass123");

    await recorder.step("Click Sign In button");
    await page.getByRole("button", { name: /sign in/i }).click();

    await recorder.step("Verify authentication error is displayed and no redirect occurs");
    await expect(page.getByText("Invalid email or password.")).toBeVisible();
    await expect(page).toHaveURL(/\/signin$/);
    await expect(page.getByRole("heading", { name: "Welcome Back" })).toBeVisible();

    console.log("CODEVALID_TEST_ASSERTION_OK:signin_invalid_credentials");
  } finally {
    await recorder.save(testInfo);
  }
});
