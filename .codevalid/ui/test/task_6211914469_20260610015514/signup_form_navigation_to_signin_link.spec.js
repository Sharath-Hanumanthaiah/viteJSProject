import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import {
  setupUnauthenticatedSession,
  mockSignUpPageApis,
} from "../../helpers/mock-api.js";

test("User can navigate to Sign In page from Signup page", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "signup_form_navigation_to_signin_link",
    testTitle: "User can navigate to Sign In page from Signup page",
  });

  try {
    let signupRequestCount = 0;

    await recorder.step("Prepare unauthenticated signup page with request tracking", async () => {
      await setupUnauthenticatedSession(page);
      await mockSignUpPageApis(page);
      await page.route("**/api/auth/signup", async (route) => {
        signupRequestCount += 1;
        await route.fulfill({
          status: 500,
          contentType: "application/json",
          body: JSON.stringify({ message: "This route should not be reached." }),
        });
      });
    });

    await recorder.step("Open signup page", async () => {
      await page.goto("/signup");
      await expect(page.getByRole("heading", { name: "Create an Account" })).toBeVisible();
    });

    await recorder.step("Click the Sign In navigation link", async () => {
      await page.getByRole("link", { name: "Sign In" }).click();
    });

    await recorder.step("Verify navigation to signin page without submitting signup form", async () => {
      await expect(page).toHaveURL(/\/signin$/);
      await expect(page.getByRole("heading", { name: "Welcome Back" })).toBeVisible();
      expect(signupRequestCount).toBe(0);
    });

    console.log("CODEVALID_TEST_ASSERTION_OK:signup_form_navigation_to_signin_link");
  } finally {
    await recorder.save(testInfo);
  }
});
