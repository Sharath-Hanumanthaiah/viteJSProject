import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import {
  setupUnauthenticatedSession,
  mockSignInPageApis,
  mockSuccessfulSigninFlow,
} from "../../helpers/mock-api.js";

const signedInUser = {
  id: "user-signin-001",
  username: "janedoe",
  email: "jane@example.com",
  fullName: "Jane Doe",
};

const authToken = "token-signin-001";

const events = [
  {
    id: "event-001",
    title: "Annual Tech Summit",
    startDate: "2099-01-10",
    endDate: "2099-01-12",
    registrationCount: 0,
  },
];

test("Successful Sign In Redirects to Home", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "home_after_successful_signin_redirects_to_home",
    testName: "Successful Sign In Redirects to Home",
  });

  try {
    await recorder.step("Prepare unauthenticated session and signin success mocks", async () => {
      await setupUnauthenticatedSession(page);
      await mockSignInPageApis(page);
      await mockSuccessfulSigninFlow(page, {
        expectedCredentials: {
          email: "jane@example.com",
          password: "secret123",
        },
        user: signedInUser,
        token: authToken,
        events,
      });

      await page.route("**/api/registrations*", async (route) => {
        if (route.request().method() === "GET") {
          await route.fulfill({
            status: 200,
            contentType: "application/json",
            body: JSON.stringify([]),
          });
        } else {
          await route.fallback();
        }
      });
    });

    await recorder.step("Navigate to sign in page", async () => {
      await page.goto("/signin");
      await expect(page.getByRole("heading", { name: "Welcome Back" })).toBeVisible();
    });

    await recorder.step("Enter valid credentials", async () => {
      await page.locator('[name="email"]').fill("jane@example.com");
      await page.locator('[name="password"]').fill("secret123");
    });

    await recorder.step("Click Sign In", async () => {
      await page.getByRole("button", { name: /sign in/i }).click();
    });

    await recorder.step("Verify redirect to home and authenticated state", async () => {
      await expect(page).toHaveURL(/\/$/);
      await expect(page.getByRole("heading", { name: "Registration Desk" })).toBeVisible();
      await expect(page.getByRole("heading", { name: "Registered Audience" })).toBeVisible();
      await expect(page.getByRole("combobox")).toBeVisible();
      await expect(page.getByRole("combobox")).toHaveValue("event-001");
      await expect
        .poll(() => page.evaluate(() => localStorage.getItem("token")))
        .toBe(authToken);
    });

    console.log("CODEVALID_TEST_ASSERTION_OK:home_after_successful_signin_redirects_to_home");
  } finally {
    await recorder.save(testInfo);
  }
});
