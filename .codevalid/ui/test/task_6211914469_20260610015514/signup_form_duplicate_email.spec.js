import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import {
  setupUnauthenticatedSession,
  mockSignUpPageApis,
} from "../../helpers/mock-api.js";

test("Signup form shows error when email is already registered", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "signup_form_duplicate_email",
    testTitle: "Signup form shows error when email is already registered",
  });

  try {
    let signupRequestCount = 0;

    await recorder.step("Prepare duplicate-email signup mock", async () => {
      await setupUnauthenticatedSession(page);
      await mockSignUpPageApis(page);
      await page.route("**/api/auth/signup", async (route) => {
        signupRequestCount += 1;
        const body = route.request().postDataJSON();
        expect(body.email).toBe("john@example.com");
        await route.fulfill({
          status: 400,
          contentType: "application/json",
          body: JSON.stringify({ message: "Username or Email already registered." }),
        });
      });
    });

    await recorder.step("Open signup page", async () => {
      await page.goto("/signup");
      await expect(page.getByRole("heading", { name: "Create an Account" })).toBeVisible();
    });

    await recorder.step("Fill form with duplicate email", async () => {
      await page.locator('[name="username"]').fill("unique_username");
      await page.locator('[name="fullName"]').fill("John Doe");
      await page.locator('[name="email"]').fill("john@example.com");
      await page.locator('[name="password"]').fill("Password123!");
    });

    await recorder.step("Submit signup form", async () => {
      await page.getByRole("button", { name: /create account/i }).click();
    });

    await recorder.step("Verify duplicate error and no redirect", async () => {
      await expect(page).toHaveURL(/\/signup$/);
      await expect(page.getByText("Username or Email already registered.")).toBeVisible();
      await expect(page.getByRole("button", { name: /create account/i })).toBeEnabled();
      expect(signupRequestCount).toBe(1);
    });

    console.log("CODEVALID_TEST_ASSERTION_OK:signup_form_duplicate_email");
  } finally {
    await recorder.save(testInfo);
  }
});
