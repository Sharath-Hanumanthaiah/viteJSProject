import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import {
  setupUnauthenticatedSession,
  mockSignUpPageApis,
} from "../../helpers/mock-api.js";

test("Signup form accepts optional phone and organization fields", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "signup_form_optional_fields_accepted",
    testTitle: "Signup form accepts optional phone and organization fields",
  });

  try {
    const createdUser = {
      id: "user_optional_fields",
      username: "optional_user",
      email: "optional@example.com",
      fullName: "Optional User",
      phone: "",
      organization: "",
    };
    const token = "simulated-jwt-token-for-user_optional_fields";
    let signupRequestCount = 0;

    await recorder.step("Prepare signup success mock for empty optional fields", async () => {
      await setupUnauthenticatedSession(page);
      await mockSignUpPageApis(page);
      await page.route("**/api/auth/signup", async (route) => {
        signupRequestCount += 1;
        const body = route.request().postDataJSON();
        expect(body).toEqual({
          username: "optional_user",
          email: "optional@example.com",
          password: "Password123!",
          fullName: "Optional User",
          phone: "",
          organization: "",
        });
        await route.fulfill({
          status: 201,
          contentType: "application/json",
          body: JSON.stringify({ user: createdUser, token }),
        });
      });
      await page.route("**/api/events", async (route) => {
        await route.fulfill({
          status: 200,
          contentType: "application/json",
          body: JSON.stringify([]),
        });
      });
    });

    await recorder.step("Open signup page and fill only required fields", async () => {
      await page.goto("/signup");
      await page.locator('[name="username"]').fill("optional_user");
      await page.locator('[name="fullName"]').fill("Optional User");
      await page.locator('[name="email"]').fill("optional@example.com");
      await page.locator('[name="password"]').fill("Password123!");
      await expect(page.locator('[name="phone"]')).toHaveValue("");
      await expect(page.locator('[name="organization"]')).toHaveValue("");
    });

    await recorder.step("Submit signup form", async () => {
      await page.getByRole("button", { name: /create account/i }).click();
    });

    await recorder.step("Verify successful redirect with no validation errors", async () => {
      await expect(page).toHaveURL(/\/$/);
      await expect(page.getByRole("heading", { name: "Registration Desk" })).toBeVisible();
      await expect(page.getByText("No Active Events")).toBeVisible();
      await expect(page.getByText("Username or Email already registered.")).toHaveCount(0);
      expect(signupRequestCount).toBe(1);
    });

    console.log("CODEVALID_TEST_ASSERTION_OK:signup_form_optional_fields_accepted");
  } finally {
    await recorder.save(testInfo);
  }
});
