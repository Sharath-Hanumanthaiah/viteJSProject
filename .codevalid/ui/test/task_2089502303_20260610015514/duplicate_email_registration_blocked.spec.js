import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { setupAuthenticatedSession } from "../../helpers/mock-api.js";
import { validUpcomingEvent, existingRegistrationForDuplicateEmail } from "../../mock/mock-data.js";

function json(route, status, body) {
  return route.fulfill({
    status,
    contentType: "application/json",
    body: JSON.stringify(body),
  });
}

test("Same email cannot register twice for the same event", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "duplicate_email_registration_blocked",
    testTitle: "Same email cannot register twice for the same event",
  });

  try {
    await recorder.step("Seed authenticated session and duplicate-registration mock", async () => {
      await setupAuthenticatedSession(page);
      await page.route("**/api/events", async (route) =>
        json(route, 200, [{ ...validUpcomingEvent, registrationCount: 1 }])
      );
      await page.route("**/api/registrations/*", async (route) =>
        json(route, 200, [existingRegistrationForDuplicateEmail])
      );
      await page.route("**/api/registrations", async (route) =>
        json(route, 400, { message: "This email is already registered for this event." })
      );
    });

    await recorder.step("Open Home and enter duplicate attendee details", async () => {
      await page.goto("/");
      await page.locator('[name="name"]').fill("Repeat User");
      await page.locator('[name="email"]').fill("user@example.com");
      await page.locator('[name="phone"]').fill("+1 (555) 111-2222");
    });

    await recorder.step("Submit and verify duplicate email error", async () => {
      await page.getByRole("button", { name: /Confirm Registration/ }).click();
      await expect(page.getByText("This email is already registered for this event.")).toBeVisible();
      await expect(page.getByText("1 Total")).toBeVisible();
      await expect(page.getByText("user@example.com")).toBeVisible();
    });

    console.log("CODEVALID_TEST_ASSERTION_OK:duplicate_email_registration_blocked");
  } finally {
    await recorder.save(testInfo);
  }
});
