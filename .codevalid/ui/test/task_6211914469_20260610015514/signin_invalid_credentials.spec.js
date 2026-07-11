import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import {
  setupUnauthenticatedSession,
  mockFailedSigninFlow,
} from "../../helpers/mock-api.js";

test("Sign In Fails With Valid Format But Invalid Credentials", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "signin_invalid_credentials",
    testTitle: "Sign In Fails With Valid Format But Invalid Credentials",
  });

  const credentials = {
    email: "invalid@example.com",
    password: "WrongPass123",
  };

  try {
    await setupUnauthenticatedSession(page);
    await mockFailedSigninFlow(page, {
      expectedCredentials: credentials,
      message: "Invalid email or password",
    });

    recorder.recordStep("Navigate to /signin", { route: "/signin" });
    await page.goto("/signin");

    await expect(page.getByRole("heading", { name: "Welcome Back" })).toBeVisible();

    recorder.recordStep("Enter invalid credentials", { email: credentials.email });
    await page.getByPlaceholder("john@example.com").fill(credentials.email);
    await page.getByPlaceholder("••••••••").fill(credentials.password);

    recorder.recordStep("Click Sign In button");
    await page.getByRole("button", { name: /sign in/i }).click();

    recorder.recordStep("Assert authentication error and no redirect");
    await expect(page).toHaveURL(/\/signin$/);
    await expect(page.getByText("Invalid email or password")).toBeVisible();
    await expect(page.getByRole("heading", { name: "Welcome Back" })).toBeVisible();

    console.log("CODEVALID_TEST_ASSERTION_OK:signin_invalid_credentials");
  } finally {
    await recorder.save(testInfo);
  }
});
