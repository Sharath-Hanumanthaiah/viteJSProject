import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import {
  setupUnauthenticatedSession,
  mockSignInPageApis,
} from "../../helpers/mock-api.js";

test("Loading state displayed during authentication request", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "signin_loading_state_on_submit",
    testTitle: "Loading state displayed during authentication request",
  });

  try {
    await recorder.step("Prepare unauthenticated session and delayed successful signin route", async () => {
      await setupUnauthenticatedSession(page);
      await mockSignInPageApis(page);
      await page.route("**/api/auth/signin", async (route) => {
        await new Promise((resolve) => setTimeout(resolve, 1200));
        await route.fulfill({
          status: 200,
          contentType: "application/json",
          body: JSON.stringify({
            user: {
              id: "user_loading_state",
              username: "loadinguser",
              email: "loading@example.com",
              fullName: "Loading State User",
              phone: "",
              organization: "CodeValid QA",
            },
            token: "simulated-jwt-token-loading-state",
          }),
        });
      });
      await page.route("**/api/events", async (route) => {
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
      await page.route("**/api/registrations/**", async (route) => {
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

    await recorder.step("Open the sign-in page", async () => {
      await page.goto("/signin");
      await expect(page.getByRole("heading", { name: "Welcome Back" })).toBeVisible();
    });

    await recorder.step("Enter valid credentials", async () => {
      await page.locator('[name="email"]').fill("loading@example.com");
      await page.locator('[name="password"]').fill("Password123");
    });

    await recorder.step("Submit and verify loading state appears immediately", async () => {
      const submitButton = page.getByRole("button", { name: /^Sign In$/ });
      await submitButton.click();
      await expect(page.getByRole("button", { name: /Signing In\.\.\./i })).toBeDisabled();
    });

    await recorder.step("Verify navigation completes after delayed response", async () => {
      await expect(page).toHaveURL(/\/$/);
    });

    console.log("CODEVALID_TEST_ASSERTION_OK:signin_loading_state_on_submit");
  } finally {
    await recorder.save(testInfo);
  }
});
