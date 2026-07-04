import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../helpers/execution-recorder.js";

test.describe("Sign In Page", () => {
  test("sample-signin - renders sign-in form and validates required fields", async ({
    page,
  }, testInfo) => {
    const recorder = new ExecutionRecorder({
      testId: "sample-signin",
      testTitle: "renders sign-in form and validates required fields",
    });

    await recorder.step("Navigate to sign-in page", async () => {
      await page.goto("/signin");
    });

    await recorder.step("Verify page title and heading are visible", async () => {
      await expect(page).toHaveTitle(/eminence hub/i);
      await expect(
        page.getByRole("heading", { name: /welcome back/i })
      ).toBeVisible();
    });

    await recorder.step("Verify email and password inputs exist", async () => {
      await expect(page.locator('input[name="email"]')).toBeVisible();
      await expect(page.locator('input[name="password"]')).toBeVisible();
    });

    await recorder.step(
      "Submit empty form and verify validation errors",
      async () => {
        await page.getByRole("button", { name: /sign in/i }).click();
        await expect(page.getByText(/email is required/i)).toBeVisible();
        await expect(page.getByText(/password is required/i)).toBeVisible();
      }
    );

    await recorder.step("Enter invalid email and verify error", async () => {
      await page.locator('input[name="email"]').fill("not-an-email");
      await page.getByRole("button", { name: /sign in/i }).click();
      await expect(page.getByText(/invalid email address/i)).toBeVisible();
    });

    await recorder.step(
      "Fill valid credentials and submit (mock intercepts API)",
      async () => {
        // Intercept the API call so no real server is needed
        await page.route("**/api/auth/signin", async (route) => {
          await route.fulfill({
            status: 200,
            contentType: "application/json",
            body: JSON.stringify({
              user: {
                id: "user_test123",
                username: "testuser",
                email: "test@example.com",
                fullName: "Test User",
              },
              token: "simulated-jwt-token-for-user_test123",
            }),
          });
        });

        await page.locator('input[name="email"]').fill("test@example.com");
        await page.locator('input[name="password"]').fill("password123");
        await page.getByRole("button", { name: /sign in/i }).click();

        // After successful sign-in, the app redirects to home "/"
        await page.waitForURL("/", { timeout: 10000 });
        await expect(page).toHaveURL("/");
      }
    );

    await recorder.save(testInfo);
  });
});
