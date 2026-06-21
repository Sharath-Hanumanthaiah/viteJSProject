import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../helpers/execution-recorder.js";

test("Successful Sign In with Valid Credentials", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder("signin_happy_path_valid_credentials", "Successful Sign In with Valid Credentials");

  await page.route("**/api/auth/signin", async (route) => {
    const request = route.request();
    const body = request.postDataJSON();

    if (body?.email === "user@example.com" && body?.password === "Password123") {
      await route.fulfill({
        status: 200,
        contentType: "application/json",
        body: JSON.stringify({
          user: {
            id: "user-1",
            username: "demo_user",
            email: "user@example.com",
            fullName: "Demo User",
            phone: "",
            organization: ""
          },
          token: "simulated-jwt-token-for-user-1"
        })
      });
      return;
    }

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
    await expect(page.getByRole("heading", { name: "Welcome Back" })).toBeVisible();

    await recorder.step("Enter valid email in email field");
    await page.getByLabel("Email Address").fill("user@example.com");

    await recorder.step("Enter valid password in password field");
    await page.getByLabel("Password").fill("Password123");

    await recorder.step("Click Sign In button");
    await page.getByRole("button", { name: /sign in/i }).click();

    await recorder.step("Verify user is redirected away from signin after successful authentication");
    await expect(page).toHaveURL(/\/$/);
    await expect(page.getByRole("heading", { name: "Welcome Back" })).not.toBeVisible();
    await expect(page.getByRole("heading", { name: /event registration portal/i })).toBeVisible();

    console.log("CODEVALID_TEST_ASSERTION_OK:signin_happy_path_valid_credentials");
  } finally {
    await recorder.save(testInfo);
  }
});
