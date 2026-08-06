import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { mockSuccessfulSigninFlow } from "../../helpers/mock-api.js";

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

test("Authenticated User Directly Accesses Home Page", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "home_authenticated_user_accesses_home_directly",
    testTitle: "Authenticated User Directly Accesses Home Page",
  });

  await recorder.step("Register successful sign-in and home API mocks", async () => {
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

  await recorder.step("Enter valid credentials and submit", async () => {
    await page.getByPlaceholder("john@example.com").fill(signinCredentials.email);
    await page.getByPlaceholder("••••••••").fill(signinCredentials.password);
    await page.getByRole("button", { name: /sign in/i }).click();
  });

  await recorder.step("Verify redirect to '/' and home renders", async () => {
    await expect(page).toHaveURL(/\/$/);
    await expect(page.getByRole("heading", { name: "Registration Desk" })).toBeVisible();
    await expect(page.locator("select")).toBeVisible();
    await expect(page.locator("select")).toHaveValue("event-001");
  });

  await recorder.step("Navigate again directly to '/' and confirm no redirection occurs", async () => {
    await page.goto("/");
    await expect(page).toHaveURL(/\/$/);
    await expect(page.getByRole("heading", { name: "Registration Desk" })).toBeVisible();
    await expect(page.locator("select")).toBeVisible();
    await expect(page.locator("select")).toHaveValue("event-001");
  });

  console.log("CODEVALID_TEST_ASSERTION_OK:home_authenticated_user_accesses_home_directly");
  await recorder.save(testInfo);
});
