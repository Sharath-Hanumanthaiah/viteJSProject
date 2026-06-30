import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import {
  setupUnauthenticatedSession,
  mockSuccessfulSigninFlow,
} from "../../helpers/mock-api.js";

const signinCredentials = {
  email: "john@example.com",
  password: "secret123",
};

const authenticatedUser = {
  id: "user-001",
  username: "johndoe",
  fullName: "John Doe",
  email: "john@example.com",
  organization: "Acme Corp",
};

const dashboardEvents = [
  {
    id: "event-001",
    title: "Annual Tech Summit",
    description: "Flagship event for the workspace.",
    location: "Main Hall",
    startDate: "2026-07-10",
    endDate: "2026-07-12",
    registrationCount: 12,
  },
];

test("Successful Sign In Redirects to Home", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "home_after_successful_signin_redirects_to_home",
    testTitle: "Successful Sign In Redirects to Home",
  });

  await recorder.step("Prepare unauthenticated session and successful sign-in mocks", async () => {
    await setupUnauthenticatedSession(page);
    await mockSuccessfulSigninFlow(page, {
      expectedCredentials: signinCredentials,
      user: authenticatedUser,
      token: "token-signin-success",
      events: dashboardEvents,
    });
  });

  await recorder.step("Navigate to '/signin'", async () => {
    await page.goto("/signin");
    await expect(page.getByRole("heading", { name: "Welcome Back" })).toBeVisible();
  });

  await recorder.step("Enter valid credentials", async () => {
    await page.getByPlaceholder("john@example.com").fill(signinCredentials.email);
    await page.getByPlaceholder("••••••••").fill(signinCredentials.password);
  });

  await recorder.step("Click 'Sign In'", async () => {
    await page.getByRole("button", { name: /sign in/i }).click();
  });

  await recorder.step("Verify redirect to route '/' and authenticated home state", async () => {
    await expect(page).toHaveURL(/\/$/);
    await expect(page.getByRole("heading", { name: "Registration Desk" })).toBeVisible();
    await expect(page.locator("select")).toBeVisible();
    await expect(page.locator("select")).toHaveValue("event-001");
    await expect(page.getByText("Select Active Event")).toBeVisible();
  });

  console.log("CODEVALID_TEST_ASSERTION_OK:home_after_successful_signin_redirects_to_home");
  await recorder.save(testInfo);
});
