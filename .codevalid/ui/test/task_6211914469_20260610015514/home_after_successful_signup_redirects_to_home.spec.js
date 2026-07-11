import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import {
  setupUnauthenticatedSession,
  mockSignUpPageApis,
  mockSuccessfulSignupFlow,
} from "../../helpers/mock-api.js";

const signedUpUser = {
  id: "user-signup-001",
  username: "johndoe",
  email: "john@example.com",
  fullName: "John Doe",
  organization: "Acme Corp",
};

const authToken = "token-signup-001";

const events = [
  {
    id: "event-001",
    title: "Annual Tech Summit",
    startDate: "2099-01-10",
    endDate: "2099-01-12",
    registrationCount: 0,
  },
];

test("Successful Sign Up Redirects to Home", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "home_after_successful_signup_redirects_to_home",
    testName: "Successful Sign Up Redirects to Home",
  });

  try {
    await recorder.step("Prepare unauthenticated session and signup success mocks", async () => {
      await setupUnauthenticatedSession(page);
      await mockSignUpPageApis(page);
      await mockSuccessfulSignupFlow(page, {
        expectedPayload: {
          username: "johndoe",
          fullName: "John Doe",
          email: "john@example.com",
          password: "secret123",
          phone: "+1 (555) 000-0000",
          organization: "Acme Corp",
        },
        user: signedUpUser,
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

    await recorder.step("Navigate to sign up page", async () => {
      await page.goto("/signup");
      await expect(page.getByRole("heading", { name: "Create an Account" })).toBeVisible();
    });

    await recorder.step("Enter valid sign up data", async () => {
      await page.locator('[name="username"]').fill("johndoe");
      await page.locator('[name="fullName"]').fill("John Doe");
      await page.locator('[name="email"]').fill("john@example.com");
      await page.locator('[name="password"]').fill("secret123");
      await page.locator('[name="phone"]').fill("+1 (555) 000-0000");
      await page.locator('[name="organization"]').fill("Acme Corp");
    });

    await recorder.step("Click Sign Up", async () => {
      await page.getByRole("button", { name: /create account/i }).click();
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

    console.log("CODEVALID_TEST_ASSERTION_OK:home_after_successful_signup_redirects_to_home");
  } finally {
    await recorder.save(testInfo);
  }
});
