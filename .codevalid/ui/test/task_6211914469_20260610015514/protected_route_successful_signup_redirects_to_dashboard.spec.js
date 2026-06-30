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

  const createdUser = {
    id: "user-002",
    username: "janedoe",
    fullName: "Jane Doe",
    email: "jane@example.com",
    organization: "Nova Labs",
    phone: "+1 (555) 000-0000",
  };

  const events = [
    {
      id: "event-101",
      title: "Organizer Onboarding Session",
      description: "Workspace starter event.",
      location: "Conference Room A",
      startDate: "2026-08-15",
      endDate: "2026-08-16",
      registrationCount: 3,
    },
  ];

  await recorder.step("Set up an unauthenticated browser session", async () => {
    await setupUnauthenticatedSession(page);
  });

  await recorder.step("Mock successful sign-up and protected home page APIs", async () => {
    await mockSuccessfulSignupFlow(page, {
      expectedPayload: {
        username: "janedoe",
        fullName: "Jane Doe",
        email: "jane@example.com",
        password: "secret123",
        phone: "+1 (555) 000-0000",
        organization: "Nova Labs",
      },
      user: createdUser,
      token: "token-signup-success",
      events,
    });
  });

  await recorder.step("Navigate to the sign-up page", async () => {
    await page.goto("/signup");
    await expect(page.getByRole("heading", { name: "Create an Account" })).toBeVisible();
  });

  await recorder.step("Enter valid sign-up details", async () => {
    await page.getByPlaceholder("johndoe").fill("janedoe");
    await page.getByPlaceholder("John Doe").fill("Jane Doe");
    await page.getByPlaceholder("john@example.com").fill("jane@example.com");
    await page.getByPlaceholder("••••••••").fill("secret123");
    await page.getByPlaceholder("+1 (555) 000-0000").fill("+1 (555) 000-0000");
    await page.getByPlaceholder("Acme Corp").fill("Nova Labs");
  });

  await recorder.step("Submit the sign-up form", async () => {
    await page.getByRole("button", { name: /create account/i }).click();
  });

  await recorder.step("Verify the user is redirected to the protected home dashboard", async () => {
    await expect(page).toHaveURL(/\/$/);
    await expect(page.getByRole("heading", { name: "Registration Desk" })).toBeVisible();
    await expect(page.getByText("Organizer Onboarding Session")).toBeVisible();
    await expect(page.getByText("Select Active Event")).toBeVisible();
  });

  await recorder.step("Verify the authenticated session is stored", async () => {
    await expect.poll(async () => page.evaluate(() => localStorage.getItem("token"))).toBe("token-signup-success");
  });

  console.log("CODEVALID_TEST_ASSERTION_OK:protected_route_successful_signup_redirects_to_dashboard");
  await recorder.save(testInfo);
});
