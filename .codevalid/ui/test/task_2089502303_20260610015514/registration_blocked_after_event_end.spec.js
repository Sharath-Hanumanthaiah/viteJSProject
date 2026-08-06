import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { setupAuthenticatedSession } from "../../helpers/mock-api.js";
import { closedPastEvent } from "../../mock/mock-data.js";

function json(route, status, body) {
  return route.fulfill({
    status,
    contentType: "application/json",
    body: JSON.stringify(body),
  });
}

test("Registration is blocked if attempted after event end date", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "registration_blocked_after_event_end",
    testTitle: "Registration is blocked if attempted after event end date",
  });

  try {
    await recorder.step("Seed authenticated session and mock closed event", async () => {
      await setupAuthenticatedSession(page);
      await page.route("**/api/events", async (route) => json(route, 200, [closedPastEvent]));
      await page.route("**/api/registrations/*", async (route) => json(route, 200, []));
    });

    await recorder.step("Open Home and verify registration is closed", async () => {
      await page.goto("/");
      await expect(page.getByText("Registration Closed")).toBeVisible();
      await expect(page.getByText(`Registration closed on ${closedPastEvent.endDate}.`)).toBeVisible();
    });

    await recorder.step("Verify form controls are disabled and no registration is recorded", async () => {
      await expect(page.locator('[name="name"]')).toBeDisabled();
      await expect(page.locator('[name="email"]')).toBeDisabled();
      await expect(page.locator('[name="phone"]')).toBeDisabled();
      await expect(page.getByRole("button", { name: /Confirm Registration/ })).toBeDisabled();
      await expect(page.getByText("0 Total")).toBeVisible();
    });

    console.log("CODEVALID_TEST_ASSERTION_OK:registration_blocked_after_event_end");
  } finally {
    await recorder.save(testInfo);
  }
});
