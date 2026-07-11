import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import {
  setupUnauthenticatedSession,
  mockSignInPageApis,
} from "../../helpers/mock-api.js";

test("Sign In Fails With Both Fields Empty", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "signin_empty_fields",
    testTitle: "Sign In Fails With Both Fields Empty",
  });

  try {
    await setupUnauthenticatedSession(page);
    await mockSignInPageApis(page);

    recorder.recordStep("Navigate to /signin", { route: "/signin" });
    await page.goto("/signin");

    await expect(page.getByRole("heading", { name: "Welcome Back" })).toBeVisible();

    recorder.recordStep("Leave both email and password fields empty");

    recorder.recordStep("Click Sign In button");
    await page.getByRole("button", { name: /sign in/i }).click();

    recorder.recordStep("Assert both validation errors are displayed and user remains on /signin");
    await expect(page).toHaveURL(/\/signin$/);
    await expect(page.getByText("Email is required")).toBeVisible();
    await expect(page.getByText("Password is required")).toBeVisible();
    await expect(page.getByRole("heading", { name: "Welcome Back" })).toBeVisible();

    console.log("CODEVALID_TEST_ASSERTION_OK:signin_empty_fields");
  } finally {
    await recorder.save(testInfo);
  }
});
