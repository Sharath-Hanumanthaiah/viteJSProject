import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import {
  setupUnauthenticatedSession,
  mockSignInPageApis,
} from "../../helpers/mock-api.js";

test("Sign In Fails When Password Field Is Empty", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "signin_missing_password",
    testTitle: "Sign In Fails When Password Field Is Empty",
  });

  try {
    await setupUnauthenticatedSession(page);
    await mockSignInPageApis(page);

    recorder.recordStep("Navigate to /signin", { route: "/signin" });
    await page.goto("/signin");

    await expect(page.getByRole("heading", { name: "Welcome Back" })).toBeVisible();

    recorder.recordStep("Enter email and leave password field empty");
    await page.getByPlaceholder("john@example.com").fill("user@example.com");

    recorder.recordStep("Click Sign In button");
    await page.getByRole("button", { name: /sign in/i }).click();

    recorder.recordStep("Assert validation blocks submission and keeps user on /signin");
    await expect(page).toHaveURL(/\/signin$/);
    await expect(page.getByText("Password is required")).toBeVisible();
    await expect(page.getByRole("heading", { name: "Welcome Back" })).toBeVisible();

    console.log("CODEVALID_TEST_ASSERTION_OK:signin_missing_password");
  } finally {
    await recorder.save(testInfo);
  }
});
