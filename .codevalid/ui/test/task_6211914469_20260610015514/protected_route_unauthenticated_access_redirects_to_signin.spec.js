import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import {
  setupUnauthenticatedSession,
  mockProtectedHomePageApis,
} from "../../helpers/mock-api.js";

test("Unauthenticated Access to Protected Route Redirects to Sign In", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder(
    "protected_route_unauthenticated_access_redirects_to_signin",
    "Unauthenticated Access to Protected Route Redirects to Sign In"
  );

  await recorder.step("Set up an unauthenticated browser session", async () => {
    await setupUnauthenticatedSession(page);
  });

  await recorder.step("Mock protected home page APIs to prevent live backend calls", async () => {
    await mockProtectedHomePageApis(page, { events: [] });
  });

  await recorder.step("Navigate directly to the protected dashboard route", async () => {
    await page.goto("/");
  });

  await recorder.step("Verify the unauthenticated user is redirected to the sign-in page", async () => {
    await expect(page).toHaveURL(/\/signin$/);
    await expect(page.getByRole("heading", { name: "Welcome Back" })).toBeVisible();
    await expect(page.getByPlaceholder("john@example.com")).toBeVisible();
    await expect(page.getByPlaceholder("••••••••")).toBeVisible();
    await expect(page.getByRole("button", { name: /sign in/i })).toBeVisible();
    await expect(page.getByRole("heading", { name: "Registration Desk" })).toHaveCount(0);
  });

  console.log("CODEVALID_TEST_ASSERTION_OK:protected_route_unauthenticated_access_redirects_to_signin");
  await recorder.save(testInfo);
});
