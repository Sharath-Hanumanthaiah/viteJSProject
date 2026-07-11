import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import {
  setupUnauthenticatedSession,
  mockSignUpPageApis,
} from "../../helpers/mock-api.js";

test("Signup Form Rejects When Email Is Missing", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "signup_missing_email",
    testName: "Signup Form Rejects When Email Is Missing",
  });

  try {
    await recorder.step("Set unauthenticated session and page mocks", async () => {
      await setupUnauthenticatedSession(page);
      await mockSignUpPageApis(page);
    });

    await recorder.step("Navigate to the signup page", async () => {
      await page.goto("/signup");
    });

    await recorder.step("Verify signup page is rendered", async () => {
      await expect(page.getByRole("heading", { name: "Create an Account" })).toBeVisible();
    });

    await recorder.step("Fill required fields except email", async () => {
      await page.locator('[name="username"]').fill("johndoe");
      await page.locator('[name="fullName"]').fill("John Doe");
      await page.locator('[name="password"]').fill("Password123!");
    });

    await recorder.step("Submit the signup form", async () => {
      await page.getByRole("button", { name: /create account/i }).click();
    });

    await recorder.step("Verify email validation blocks submission", async () => {
      await expect(page).toHaveURL(/\/signup$/);
      await expect(page.getByText("Email is required")).toBeVisible();
      await expect(page.locator('[name="username"]')).toHaveValue("johndoe");
      await expect(page.locator('[name="fullName"]')).toHaveValue("John Doe");
      await expect(page.locator('[name="password"]')).toHaveValue("Password123!");
      await expect.poll(() => page.evaluate(() => localStorage.getItem("token"))).toBeNull();
    });

    console.log("CODEVALID_TEST_ASSERTION_OK:signup_missing_email");
  } finally {
    await recorder.save(testInfo);
  }
});
