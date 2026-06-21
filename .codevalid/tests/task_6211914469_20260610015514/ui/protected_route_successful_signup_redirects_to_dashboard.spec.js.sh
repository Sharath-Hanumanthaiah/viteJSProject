import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../helpers/execution-recorder.js";
import { mockHomePageApis } from "../helpers/mock-api.js";

test("Successful Sign Up Redirects to Dashboard", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "protected_route_successful_signup_redirects_to_dashboard",
    testTitle: "Successful Sign Up Redirects to Dashboard",
  });

  await recorder.step("Clear any existing session and register sign up and protected-page API mocks", async () => {
    await page.goto("/signup");
    await page.evaluate(() => {
      localStorage.removeItem("user");
      localStorage.removeItem("token");
    });

    await page.route("**/api/auth/signup", async (route) => {
      if (route.request().method() !== "POST") {
        await route.continue();
        return;
      }

      await route.fulfill({
        status: 201,
        contentType: "application/json",
        body: JSON.stringify({
          user: {
            id: "user_signup1",
            username: "janedoe",
            email: "jane@example.com",
            fullName: "Jane Doe",
            phone: "+1 (555) 000-0000",
            organization: "Acme Corp",
          },
          token: "simulated-jwt-token-for-user_signup1",
        }),
      });
    });

    await mockHomePageApis(page);
  });

  await recorder.step("Navigate to the sign up page", async () => {
    await page.goto("/signup");
    await expect(page.getByRole("heading", { name: "Create an Account" })).toBeVisible();
  });

  await recorder.step("Enter valid sign up data into all required fields", async () => {
    await page.getByPlaceholder("johndoe").fill("janedoe");
    await page.getByPlaceholder("John Doe").fill("Jane Doe");
    await page.getByPlaceholder("john@example.com").fill("jane@example.com");
    await page.getByPlaceholder("••••••••").fill("secure123");
    await page.getByPlaceholder("+1 (555) 000-0000").fill("+1 (555) 000-0000");
    await page.getByPlaceholder("Acme Corp").fill("Acme Corp");
  });

  await recorder.step("Submit the sign up form", async () => {
    await page.getByRole("button", { name: /create account/i }).click();
  });

  await recorder.step("Verify the newly authenticated user is redirected to the protected home page and the dashboard content is rendered", async () => {
    await expect(page).toHaveURL(/\/$/);
    await expect(page.getByRole("heading", { name: "Registration Desk" })).toBeVisible();
    await expect(page.getByText("Select Active Event")).toBeVisible();
    await expect(page.getByText("Registered Audience")).toBeVisible();
  });

  console.log("CODEVALID_TEST_ASSERTION_OK:protected_route_successful_signup_redirects_to_dashboard");
  await recorder.save(testInfo);
});
