import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import {
  setupUnauthenticatedSession,
  mockSignInPageApis,
  mockSuccessfulSigninFlow,
} from "../../helpers/mock-api.js";

const signedInUser = {
  id: "user-auth-home-001",
  username: "janedoe",
  email: "jane@example.com",
  fullName: "Jane Doe",
};

const authToken = "token-auth-home-001";

const events = [
  {
    id: "event-001",
    title: "Annual Tech Summit",
    startDate: "2099-01-10",
    endDate: "2099-01-12",
    registrationCount: 0,
  },
];

test("Authenticated User Directly Accesses Home Page", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "home_authenticated_user_accesses_home_directly",
    testName: "Authenticated User Directly Accesses Home Page",
  });

  try {
    await recorder.step("Prepare unauthenticated session and signin mocks", async () => {
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

    await recorder.step("Enter valid credentials and submit", async () => {
      await page.locator('[name="email"]').fill("jane@example.com");
      await page.locator('[name="password"]').fill("secret123");
      await page.getByRole("button", { name: /sign in/i }).click();
    });

    await recorder.step("Verify redirect to home after sign in", async () => {
      await expect(page).toHaveURL(/\/$/);
      await expect(page.getByRole("heading", { name: "Registration Desk" })).toBeVisible();
      await expect(page.getByRole("heading", { name: "Registered Audience" })).toBeVisible();
      await expect(page.getByRole("combobox")).toBeVisible();
      await expect(page.getByRole("combobox")).toHaveValue("event-001");
    });

    await recorder.step("Verify token persisted to localStorage", async () => {
      await expect
        .poll(() => page.evaluate(() => localStorage.getItem("token")))
        .toBe(authToken);
    });

    await recorder.step("Navigate directly to home again while authenticated", async () => {
      await page.goto("/");
    });

    await recorder.step("Verify home remains accessible without redirect", async () => {
      await expect(page).toHaveURL(/\/$/);
      await expect(page.getByRole("heading", { name: "Registration Desk" })).toBeVisible();
      await expect(page.getByText("No Registered Attendees")).toBeVisible();
    });

    console.log("CODEVALID_TEST_ASSERTION_OK:home_authenticated_user_accesses_home_directly");
  } finally {
    await recorder.save(testInfo);
  }
});
