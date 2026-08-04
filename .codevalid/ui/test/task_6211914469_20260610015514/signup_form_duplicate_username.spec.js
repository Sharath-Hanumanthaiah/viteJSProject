import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import {
  setupUnauthenticatedSession,
  mockSignUpPageApis,
} from "../../helpers/mock-api.js";

test("Signup form shows error when username is already taken", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "signup_form_duplicate_username",
    testTitle: "Signup form shows error when username is already taken",
  });

  try {
    let signupRequestCount = 0;

    await recorder.step("Prepare duplicate-username signup mock", async () => {
      await setupUnauthenticatedSession(page);
      await mockSignUpPageApis(page);
      await page.route("**/api/auth/signup", async (route) => {
        signupRequestCount += 1;
        const body = route.request().postDataJSON();
        expect(body.username).toBe("john_doe");
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

    await recorder.step("Fill form with duplicate username", async () => {
      await page.locator('[name="username"]').fill("john_doe");
      await page.locator('[name="fullName"]').fill("John Doe");
      await page.locator('[name="email"]').fill("unique@example.com");
      await page.locator('[name="password"]').fill("Password123!");
    });

    await recorder.step("Submit signup form", async () => {
      await page.getByRole("button", { name: /create account/i }).click();
    });

    await recorder.step("Verify duplicate error and stay on signup page", async () => {
      await expect(page).toHaveURL(/\/signup$/);
      await expect(page.getByText("Username or Email already registered.")).toBeVisible();
      await expect(page.getByRole("button", { name: /create account/i })).toBeEnabled();
      expect(signupRequestCount).toBe(1);
    });

    console.log("CODEVALID_TEST_ASSERTION_OK:signup_form_duplicate_username");
  } finally {
    await recorder.save(testInfo);
  }
});
