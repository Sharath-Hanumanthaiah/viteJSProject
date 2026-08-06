import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { setupUnauthenticatedSession } from "../../helpers/mock-api.js";

test("Sign In Fails With Both Fields Empty", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "signin_empty_fields",
    testTitle: "Sign In Fails With Both Fields Empty",
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

    recorder.recordStep("Leave both fields empty");
    await page.getByPlaceholder("john@example.com").fill("");
    await page.getByPlaceholder("••••••••").fill("");

    recorder.recordStep("Submit signin form");
    await page.getByRole("button", { name: /sign in/i }).click();

    recorder.recordStep("Assert both validation errors and no submission");
    await expect(page.getByText("Email is required")).toBeVisible();
    await expect(page.getByText("Password is required")).toBeVisible();
    await expect(page).toHaveURL(/\/signin$/);
    await expect(page.getByRole("heading", { name: "Welcome Back" })).toBeVisible();
    expect(signinRequestCount).toBe(0);

    console.log("CODEVALID_TEST_ASSERTION_OK:signin_empty_fields");
  } finally {
    await recorder.save(testInfo);
  }
});
