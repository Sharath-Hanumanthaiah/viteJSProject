import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { setupUnauthenticatedSession } from "../../helpers/mock-api.js";

test("Sign In Fails When Password Field Is Empty", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "signin_missing_password",
    testTitle: "Sign In Fails When Password Field Is Empty",
  });

  let signinRequestCount = 0;

  await setupUnauthenticatedSession(page);
  await page.route("**/api/auth/signin", async (route) => {
    signinRequestCount += 1;
    await route.fulfill({
      status: 500,
      contentType: "application/json",
      body: JSON.stringify({ message: "Signin API should not be called for client-side validation failures" }),
    });
  });

  try {
    recorder.recordStep("Navigate to /signin", { route: "/signin" });
    await page.goto("/signin");

    recorder.recordStep("Enter email and leave password empty");
    await page.getByPlaceholder("john@example.com").fill("user@example.com");
    await page.getByPlaceholder("••••••••").fill("");

    recorder.recordStep("Submit signin form");
    await page.getByRole("button", { name: /sign in/i }).click();

    recorder.recordStep("Assert password validation error and no submission");
    await expect(page.getByText("Password is required")).toBeVisible();
    await expect(page.getByText("Email is required")).not.toBeVisible();
    await expect(page).toHaveURL(/\/signin$/);
    await expect(page.getByRole("heading", { name: "Welcome Back" })).toBeVisible();
    expect(signinRequestCount).toBe(0);

    console.log("CODEVALID_TEST_ASSERTION_OK:signin_missing_password");
  } finally {
    await recorder.save(testInfo);
  }
});
