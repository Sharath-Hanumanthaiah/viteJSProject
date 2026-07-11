import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import {
  setupUnauthenticatedSession,
  mockSuccessfulSignupFlow,
} from "../../helpers/mock-api.js";

test("Successful Sign Up Redirects to Dashboard", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder(
    "protected_route_successful_signup_redirects_to_dashboard",
    "Successful Sign Up Redirects to Dashboard"
  );

  const signedUpUser = {
    id: "user-002",
    username: "janedoe",
    fullName: "Jane Doe",
    email: "jane@example.com",
    organization: "Example Org",
  };

  const events = [
    {
      id: "event-100",
      title: "Community Launch Night",
      description: "First event available after signup.",
      location: "Auditorium",
      startDate: "2026-08-01",
      endDate: "2026-08-02",
      registrationCount: 0,
    },
  ];

  await recorder.step("Set up an unauthenticated browser session", async () => {
    await setupUnauthenticatedSession(page);
  });

  await recorder.step("Mock successful sign-up and protected home page APIs", async () => {
    await mockSuccessfulSignupFlow(page, {
      user: signedUpUser,
      token: "token-signup-success",
      events,
    });
  });

  await recorder.step("Navigate to the sign-up page", async () => {
    await page.goto("/signup");
    await expect(page.getByRole("heading", { name: "Create Account" })).toBeVisible();
  });

  await recorder.step("Enter valid signup information", async () => {
    await page.getByPlaceholder("johndoe").fill("janedoe");
    await page.getByPlaceholder("John Doe").fill("Jane Doe");
    await page.getByPlaceholder("john@example.com").fill("jane@example.com");
    await page.locator('input[placeholder="••••••••"]').nth(0).fill("secret123");
    await page.locator('input[placeholder="••••••••"]').nth(1).fill("secret123");
    await page.getByPlaceholder("Your company or organization").fill("Example Org");
  });

  await recorder.step("Submit the sign-up form", async () => {
    await page.getByRole("button", { name: /create account/i }).click();
  });

  await recorder.step("Verify the user is redirected to the protected home dashboard", async () => {
    await expect(page).toHaveURL(/\/$/);
    await expect(page.getByRole("heading", { name: "Registration Desk" })).toBeVisible();
    await expect(page.locator("select")).toBeVisible();
    await expect(page.locator("select")).toHaveValue("event-100");
    await expect(page.getByText("Select Active Event")).toBeVisible();
  });

  await recorder.step("Verify the session token is stored for authenticated access", async () => {
    await expect.poll(async () => page.evaluate(() => localStorage.getItem("token"))).toBe("token-signup-success");
  });

  console.log("CODEVALID_TEST_ASSERTION_OK:protected_route_successful_signup_redirects_to_dashboard");
  await recorder.save(testInfo);
});
