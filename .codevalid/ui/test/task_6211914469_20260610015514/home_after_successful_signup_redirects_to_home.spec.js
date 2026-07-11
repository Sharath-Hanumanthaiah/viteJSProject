import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import {
  setupUnauthenticatedSession,
  mockSuccessfulSignupFlow,
} from "../../helpers/mock-api.js";

const signupPayload = {
  username: "janedoe",
  fullName: "Jane Doe",
  email: "jane@example.com",
  password: "secret123",
  phone: "+1 (555) 000-0000",
  organization: "Nova Labs",
};

const createdUser = {
  id: "user-002",
  username: "janedoe",
  fullName: "Jane Doe",
  email: "jane@example.com",
  organization: "Nova Labs",
  phone: "+1 (555) 000-0000",
};

const dashboardEvents = [
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

test("Successful Sign Up Redirects to Home", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "home_after_successful_signup_redirects_to_home",
    testTitle: "Successful Sign Up Redirects to Home",
  });

  await recorder.step("Prepare unauthenticated session and successful sign-up mocks", async () => {
    await setupUnauthenticatedSession(page);
    await mockSuccessfulSignupFlow(page, {
      expectedPayload: signupPayload,
      user: createdUser,
      token: "token-signup-success",
      events: dashboardEvents,
    });
  });

  await recorder.step("Navigate to '/signup'", async () => {
    await page.goto("/signup");
    await expect(page.getByRole("heading", { name: "Create an Account" })).toBeVisible();
  });

  await recorder.step("Enter valid sign up data", async () => {
    await page.getByPlaceholder("johndoe").fill(signupPayload.username);
    await page.getByPlaceholder("John Doe").fill(signupPayload.fullName);
    await page.getByPlaceholder("john@example.com").fill(signupPayload.email);
    await page.getByPlaceholder("••••••••").fill(signupPayload.password);
    await page.getByPlaceholder("+1 (555) 000-0000").fill(signupPayload.phone);
    await page.getByPlaceholder("Acme Corp").fill(signupPayload.organization);
  });

  await recorder.step("Submit the sign-up form", async () => {
    await page.getByRole("button", { name: /create account/i }).click();
  });

  await recorder.step("Verify redirect to route '/' and authenticated home state", async () => {
    await expect(page).toHaveURL(/\/$/);
    await expect(page.getByRole("heading", { name: "Registration Desk" })).toBeVisible();
    await expect(page.locator("select")).toBeVisible();
    await expect(page.locator("select")).toHaveValue("event-101");
    await expect(page.getByText("Select Active Event")).toBeVisible();
  });

  console.log("CODEVALID_TEST_ASSERTION_OK:home_after_successful_signup_redirects_to_home");
  await recorder.save(testInfo);
});
