import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../helpers/execution-recorder.js";

test("Sign In Fails When Email Field Is Empty", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder("signin_missing_email", "Sign In Fails When Email Field Is Empty");
  let signinRequestCount = 0;

  await page.route("**/api/auth/signin", async (route) => {
    signinRequestCount += 1;
    await route.fulfill({
      status: 400,
      contentType: "application/json",
      body: JSON.stringify({ message: "Email and password are required." })
    });
  });

  try {
    await recorder.step("Navigate to /signin");
    await page.goto("/signin");
    await expect(page).toHaveURL(/\/signin$/);

    await recorder.step("Leave email field empty and enter password");
    await page.getByLabel("Password").fill("Password123");

    await recorder.step("Click Sign In button");
    await page.getByRole("button", { name: /sign in/i }).click();

    await recorder.step("Verify validation error is shown and submission is blocked");
    await expect(page.getByText("Email is required")).toBeVisible();
    await expect(page).toHaveURL(/\/signin$/);
    await expect.poll(() => signinRequestCount).toBe(0);

    console.log("CODEVALID_TEST_ASSERTION_OK:signin_missing_email");
  } finally {
    await recorder.save(testInfo);
  }
});
