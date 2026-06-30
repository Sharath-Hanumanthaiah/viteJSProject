import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import {
  setupUnauthenticatedSession,
  mockSuccessfulSigninFlow,
} from "../../helpers/mock-api.js";

test("Successful Sign In Redirects to Dashboard", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder(
    "protected_route_successful_signin_redirects_to_dashboard",
    "Successful Sign In Redirects to Dashboard"
  );

  const signedInUser = {
    id: "user-001",
    username: "johndoe",
    fullName: "John Doe",
    email: "john@example.com",
    organization: "Acme Corp",
  };

  const events = [
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

  await recorder.step("Set up an unauthenticated browser session", async () => {
    await setupUnauthenticatedSession(page);
  });

  await recorder.step("Mock successful sign-in and protected home page APIs", async () => {
    await mockSuccessfulSigninFlow(page, {
      expectedCredentials: {
        email: "john@example.com",
        password: "secret123",
      },
      user: signedInUser,
      token: "token-signin-success",
      events,
    });
  });

  await recorder.step("Navigate to the sign-in page", async () => {
    await page.goto("/signin");
    await expect(page.getByRole("heading", { name: "Welcome Back" })).toBeVisible();
  });

  await recorder.step("Enter valid credentials", async () => {
    await page.getByPlaceholder("john@example.com").fill("john@example.com");
    await page.getByPlaceholder("••••••••").fill("secret123");
  });

  await recorder.step("Submit the sign-in form", async () => {
    await page.getByRole("button", { name: /sign in/i }).click();
  });

  await recorder.step("Verify the user is redirected to the protected home dashboard", async () => {
    await expect(page).toHaveURL(/\/$/);
    await expect(page.getByRole("heading", { name: "Registration Desk" })).toBeVisible();
    await expect(page.getByText("Annual Tech Summit")).toBeVisible();
    await expect(page.getByText("Select Active Event")).toBeVisible();
  });

  await recorder.step("Verify the session token is stored for authenticated access", async () => {
    await expect.poll(async () => page.evaluate(() => localStorage.getItem("token"))).toBe("token-signin-success");
  });

  console.log("CODEVALID_TEST_ASSERTION_OK:protected_route_successful_signin_redirects_to_dashboard");
  await recorder.save(testInfo);
});
