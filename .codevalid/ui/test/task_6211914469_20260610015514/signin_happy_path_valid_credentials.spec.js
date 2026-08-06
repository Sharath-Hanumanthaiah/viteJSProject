import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import {
  setupUnauthenticatedSession,
  mockSuccessfulSigninFlow,
} from "../../helpers/mock-api.js";

test("Successful Sign In with Valid Credentials", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "signin_happy_path_valid_credentials",
    testTitle: "Successful Sign In with Valid Credentials",
  });

  const credentials = {
    email: "user@example.com",
    password: "Password123",
  };

  const authenticatedUser = {
    id: "user-1",
    username: "johndoe",
    fullName: "John Doe",
    email: "user@example.com",
  };

  await setupUnauthenticatedSession(page);
  await mockSuccessfulSigninFlow(page, {
    expectedCredentials: credentials,
    user: authenticatedUser,
    token: "token-valid-user",
    events: [],
  });

  try {
    recorder.recordStep("Navigate to /signin", { route: "/signin" });
    await page.goto("/signin");

    await expect(page.getByRole("heading", { name: "Welcome Back" })).toBeVisible();

    recorder.recordStep("Enter valid email", { email: credentials.email });
    await page.getByPlaceholder("john@example.com").fill(credentials.email);

    recorder.recordStep("Enter valid password");
    await page.getByPlaceholder("••••••••").fill(credentials.password);

    recorder.recordStep("Click Sign In button");
    await page.getByRole("button", { name: /sign in/i }).click();

    recorder.recordStep("Assert redirect to authenticated home route");
    await expect(page).toHaveURL(/\/$/);
    await expect(page.getByRole("heading", { name: "Registration Desk" })).toBeVisible();
    await expect(page.getByRole("heading", { name: "Welcome Back" })).not.toBeVisible();

    console.log("CODEVALID_TEST_ASSERTION_OK:signin_happy_path_valid_credentials");
  } finally {
    await recorder.save(testInfo);
  }
});
