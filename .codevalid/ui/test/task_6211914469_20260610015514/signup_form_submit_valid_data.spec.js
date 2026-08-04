import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import {
  setupUnauthenticatedSession,
  mockSignUpPageApis,
  mockSuccessfulSignupFlow,
} from "../../helpers/mock-api.js";

test("User successfully signs up with all required fields", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "signup_form_submit_valid_data",
    testTitle: "User successfully signs up with all required fields",
  });

  try {
    const createdUser = {
      id: "user_john_doe",
      username: "john_doe",
      email: "john@example.com",
      fullName: "John Doe",
      phone: "+1 (555) 000-0000",
      organization: "Acme Corp",
    };
    const token = "simulated-jwt-token-for-user_john_doe";
    let signupRequestCount = 0;

    await recorder.step("Set unauthenticated session and register signup success mocks", async () => {
      await setupUnauthenticatedSession(page);
      await mockSignUpPageApis(page);
      await mockSuccessfulSignupFlow(page, {
        user: createdUser,
        token,
        events: [],
      });
      await page.route("**/api/auth/signup", async (route) => {
        signupRequestCount += 1;
        const body = route.request().postDataJSON();
        expect(body).toEqual({
          username: "john_doe",
          email: "john@example.com",
          password: "Password123!",
          fullName: "John Doe",
          phone: "+1 (555) 000-0000",
          organization: "Acme Corp",
        });
        await route.fulfill({
          status: 201,
          contentType: "application/json",
          body: JSON.stringify({ user: createdUser, token }),
        });
      });
    });

    await recorder.step("Open signup page", async () => {
      await page.goto("/signup");
      await expect(page.getByRole("heading", { name: "Create an Account" })).toBeVisible();
    });

    await recorder.step("Fill all required and optional signup fields", async () => {
      await page.locator('[name="username"]').fill("john_doe");
      await page.locator('[name="fullName"]').fill("John Doe");
      await page.locator('[name="email"]').fill("john@example.com");
      await page.locator('[name="password"]').fill("Password123!");
      await page.locator('[name="phone"]').fill("+1 (555) 000-0000");
      await page.locator('[name="organization"]').fill("Acme Corp");
    });

    await recorder.step("Submit signup form", async () => {
      await page.getByRole("button", { name: /create account/i }).click();
    });

    await recorder.step("Verify redirect to dashboard and no error is shown", async () => {
      await expect(page).toHaveURL(/\/$/);
      await expect(page.getByRole("heading", { name: "Registration Desk" })).toBeVisible();
      await expect(page.getByText("Username or Email already registered.")).toHaveCount(0);
      await expect(page.getByText("Invalid email address")).toHaveCount(0);
      await expect(page.getByText("Password is required")).toHaveCount(0);
      await expect(page.getByText("Full name is required")).toHaveCount(0);
      expect(signupRequestCount).toBe(1);
    });

    console.log("CODEVALID_TEST_ASSERTION_OK:signup_form_submit_valid_data");
  } finally {
    await recorder.save(testInfo);
  }
});
