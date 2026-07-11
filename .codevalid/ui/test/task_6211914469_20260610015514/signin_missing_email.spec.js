import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import {
  setupUnauthenticatedSession,
  mockSignInPageApis,
} from "../../helpers/mock-api.js";

test("Sign In Fails When Email Field Is Empty", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "signin_missing_email",
    testTitle: "Sign In Fails When Email Field Is Empty",
  });

  try {
    await setupUnauthenticatedSession(page);
    await mockSignInPageApis(page);

    recorder.recordStep("Navigate to /signin", { route: "/signin" });
    await page.goto("/signin");

    await expect(page.getByRole("heading", { name: "Welcome Back" })).toBeVisible();

    recorder.recordStep("Leave email field empty and enter password only");
    await page.getByPlaceholder("••••••••").fill("Password123");

    recorder.recordStep("Click Sign In button");
    await page.getByRole("button", { name: /sign in/i }).click();

    recorder.recordStep("Assert validation blocks submission and keeps user on /signin");
    await expect(page).toHaveURL(/\/signin$/);
    await expect(page.getByText("Email is required")).toBeVisible();
    await expect(page.getByRole("heading", { name: "Welcome Back" })).toBeVisible();

    console.log("CODEVALID_TEST_ASSERTION_OK:signin_missing_email");
  } finally {
    await recorder.save(testInfo);
  }
});
