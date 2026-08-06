import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { setupAuthenticatedSession } from "../../helpers/mock-api.js";
import { futureRegistrationEvent } from "../../mock/mock-data.js";

function json(route, status, body) {
  return route.fulfill({
    status,
    contentType: "application/json",
    body: JSON.stringify(body),
  });
}

test("Registration is blocked if attempted before event start date", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "registration_blocked_before_event_start",
    testTitle: "Registration is blocked if attempted before event start date",
  });

  try {
    await recorder.step("Seed authenticated session and mock future event", async () => {
      await setupAuthenticatedSession(page);
      await page.route("**/api/events", async (route) => json(route, 200, [futureRegistrationEvent]));
      await page.route("**/api/registrations/*", async (route) => json(route, 200, []));
    });

    await recorder.step("Open Home and verify registration is not open yet", async () => {
      await page.goto("/");
      await expect(page.getByText("Registration Upcoming")).toBeVisible();
      await expect(page.getByText(`Registration opens on ${futureRegistrationEvent.startDate}.`)).toBeVisible();
    });

    await recorder.step("Verify the registration form cannot be submitted", async () => {
      await expect(page.locator('[name="name"]')).toBeDisabled();
      await expect(page.locator('[name="email"]')).toBeDisabled();
      await expect(page.locator('[name="phone"]')).toBeDisabled();
      await expect(page.getByRole("button", { name: /Confirm Registration/ })).toBeDisabled();
      await expect(page.getByText("0 Total")).toBeVisible();
    });

    console.log("CODEVALID_TEST_ASSERTION_OK:registration_blocked_before_event_start");
  } finally {
    await recorder.save(testInfo);
  }
});
