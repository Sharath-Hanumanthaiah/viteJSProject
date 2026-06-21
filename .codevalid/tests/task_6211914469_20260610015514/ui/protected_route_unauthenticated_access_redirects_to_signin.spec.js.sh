import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../helpers/execution-recorder.js";
import { mockHomePageApis } from "../helpers/mock-api.js";

test("Unauthenticated Access to Protected Route Redirects to Sign In", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "protected_route_unauthenticated_access_redirects_to_signin",
    testTitle: "Unauthenticated Access to Protected Route Redirects to Sign In",
  });

  await recorder.step("Clear any existing user session to ensure the user is unauthenticated", async () => {
    await page.goto("/signin");
    await page.evaluate(() => {
      localStorage.removeItem("user");
      localStorage.removeItem("token");
    });
  });

  await recorder.step("Register protected page API mocks in case the route briefly attempts authenticated page fetches", async () => {
    await mockHomePageApis(page);
  });

  await recorder.step("Navigate directly to the protected home route", async () => {
    await page.goto("/");
  });

  await recorder.step("Verify the user is redirected to the sign in page and protected content is not shown", async () => {
    await expect(page).toHaveURL(/\/signin$/);
    await expect(page.getByRole("heading", { name: "Welcome Back" })).toBeVisible();
    await expect(page.getByRole("button", { name: /sign in/i })).toBeVisible();
    await expect(page.getByRole("heading", { name: "Registration Desk" })).not.toBeVisible();
  });

  console.log("CODEVALID_TEST_ASSERTION_OK:protected_route_unauthenticated_access_redirects_to_signin");
  await recorder.save(testInfo);
});
