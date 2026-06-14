import { test, expect } from "@playwright/test";
import { setupSignInMocks } from "../helpers/mock-api.js";
import { ExecutionRecorder } from "../helpers/execution-recorder.js";

const SIGNIN_URL = "/signin";
const VALID_EMAIL = "john@example.com";
const VALID_PASSWORD = "correctpassword";

test.describe("SignIn Component", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto(SIGNIN_URL);
    await expect(page.getByRole("heading", { name: "Welcome Back" })).toBeVisible();
  });

  test("AC1: fill all details and submit routes to home page", async ({ page }, testInfo) => {
    const recorder = new ExecutionRecorder("AC1", testInfo.title);
    recorder.record("navigate", { url: SIGNIN_URL });
    recorder.record("mock_api", {
      endpoints: ["POST /api/auth/signin [success]", "GET /api/events", "GET /api/registrations/event_test1"],
    });

    await setupSignInMocks(page, { signInScenario: "success", includeHomeApis: true });

    recorder.record("fill_email", { value: VALID_EMAIL });
    await page.getByPlaceholder("john@example.com").fill(VALID_EMAIL);

    recorder.record("fill_password", { value: VALID_PASSWORD });
    await page.getByPlaceholder("••••••••").fill(VALID_PASSWORD);

    recorder.record("click_submit", { button: "Sign In" });
    await page.getByRole("button", { name: /sign in/i }).click();

    recorder.record("assert_navigation", { expectedPath: "/" });
    await expect(page).toHaveURL("/");

    recorder.record("assert_home_content", { expectedHeading: "Registration Desk" });
    await expect(page.getByRole("heading", { name: "Registration Desk" })).toBeVisible();

    await recorder.save(testInfo);
  });

  test("AC2: missing password shows error message", async ({ page }, testInfo) => {
    const recorder = new ExecutionRecorder("AC2", testInfo.title);
    recorder.record("navigate", { url: SIGNIN_URL });
    recorder.record("mock_api", { note: "No API call expected — client-side validation only" });

    recorder.record("fill_email", { value: VALID_EMAIL });
    await page.getByPlaceholder("john@example.com").fill(VALID_EMAIL);

    recorder.record("leave_password_empty", {});
    await page.getByPlaceholder("••••••••").fill("");

    recorder.record("click_submit", { button: "Sign In" });
    await page.getByRole("button", { name: /sign in/i }).click();

    recorder.record("assert_error", { expectedMessage: "Password is required" });
    await expect(page.getByText("Password is required")).toBeVisible();
    await expect(page).toHaveURL(SIGNIN_URL);

    await recorder.save(testInfo);
  });

  test("AC3: invalid email shows error message", async ({ page }, testInfo) => {
    const recorder = new ExecutionRecorder("AC3", testInfo.title);
    recorder.record("navigate", { url: SIGNIN_URL });
    recorder.record("mock_api", { note: "No API call expected — client-side validation only" });

    recorder.record("fill_invalid_email", { value: "john@example" });
    await page.getByPlaceholder("john@example.com").fill("john@example");

    recorder.record("fill_password", { value: VALID_PASSWORD });
    await page.getByPlaceholder("••••••••").fill(VALID_PASSWORD);

    recorder.record("click_submit", { button: "Sign In" });
    await page.getByRole("button", { name: /sign in/i }).click();

    recorder.record("assert_error", { expectedMessage: "Invalid email address" });
    await expect(page.getByText("Invalid email address")).toBeVisible();
    await expect(page).toHaveURL(SIGNIN_URL);

    await recorder.save(testInfo);
  });

  test("AC4: wrong password shows error message", async ({ page }, testInfo) => {
    const recorder = new ExecutionRecorder("AC4", testInfo.title);
    recorder.record("navigate", { url: SIGNIN_URL });
    recorder.record("mock_api", {
      endpoints: ["POST /api/auth/signin [invalid_credentials]"],
    });

    await setupSignInMocks(page, { signInScenario: "invalid_credentials" });

    recorder.record("fill_email", { value: VALID_EMAIL });
    await page.getByPlaceholder("john@example.com").fill(VALID_EMAIL);

    recorder.record("fill_wrong_password", { value: "wrongpassword" });
    await page.getByPlaceholder("••••••••").fill("wrongpassword");

    recorder.record("click_submit", { button: "Sign In" });
    await page.getByRole("button", { name: /sign in/i }).click();

    recorder.record("assert_api_error", { expectedMessage: "Invalid email or password." });
    await expect(page.getByText("Invalid email or password.")).toBeVisible();
    await expect(page).toHaveURL(SIGNIN_URL);

    await recorder.save(testInfo);
  });
});
