import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { setupUnauthenticatedSession } from "../../helpers/mock-api.js";

test("Sign In Fails With Valid Format But Invalid Credentials", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "signin_invalid_credentials",
    testTitle: "Sign In Fails With Valid Format But Invalid Credentials",
  });

  const invalidCredentials = {
    email: "invalid@example.com",
    password: "WrongPass123",
  };

  await setupUnauthenticatedSession(page);
  await page.route("**/api/auth/signin", async (route) => {
    const request = route.request();
    if (request.method() !== "POST") {
      await route.fallback();
      return;
    }

    const payload = JSON.parse(request.postData() || "{}");
    expect(payload).toEqual(invalidCredentials);

    await route.fulfill({
      status: 401,
      contentType: "application/json",
      body: JSON.stringify({ message: "Invalid email or password" }),
    });
  });

  try {
    recorder.recordStep("Navigate to /signin", { route: "/signin" });
    await page.goto("/signin");

    recorder.recordStep("Enter invalid but well-formed email", { email: invalidCredentials.email });
    await page.getByPlaceholder("john@example.com").fill(invalidCredentials.email);

    recorder.recordStep("Enter invalid password");
    await page.getByPlaceholder("••••••••").fill(invalidCredentials.password);

    recorder.recordStep("Submit signin form");
    await page.getByRole("button", { name: /sign in/i }).click();

    recorder.recordStep("Assert authentication error and no redirect");
    await expect(page.getByText("Invalid email or password")).toBeVisible();
    await expect(page).toHaveURL(/\/signin$/);
    await expect(page.getByRole("heading", { name: "Welcome Back" })).toBeVisible();
    await expect(page.getByRole("heading", { name: "Registration Desk" })).not.toBeVisible();

    console.log("CODEVALID_TEST_ASSERTION_OK:signin_invalid_credentials");
  } finally {
    await recorder.save(testInfo);
  }
});
