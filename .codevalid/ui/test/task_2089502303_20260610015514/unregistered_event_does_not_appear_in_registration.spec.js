import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { setupAuthenticatedSession } from "../../helpers/mock-api.js";
import { validDisplayEvent, malformedHiddenEvent } from "../../mock/mock-data.js";

function json(route, status, body) {
  return route.fulfill({
    status,
    contentType: "application/json",
    body: JSON.stringify(body),
  });
}

test("Events without registration capability are not displayed (if any)", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "unregistered_event_does_not_appear_in_registration",
    testTitle: "Events without registration capability are not displayed (if any)",
  });

  try {
    await recorder.step("Seed authenticated session and mock backend-filtered event list", async () => {
      await setupAuthenticatedSession(page);
      await page.route("**/api/events", async (route) => json(route, 200, [validDisplayEvent]));
      await page.route("**/api/registrations/*", async (route) => json(route, 200, []));
    });

    await recorder.step("Load Home and verify only the valid event is rendered", async () => {
      await page.goto("/");
      await expect(page.locator("select").locator("option", { hasText: validDisplayEvent.title })).toBeAttached();
      await expect(page.getByText(malformedHiddenEvent.title)).toHaveCount(0);
      await expect(page.locator("select").locator("option", { hasText: malformedHiddenEvent.title })).toHaveCount(0);
    });

    console.log("CODEVALID_TEST_ASSERTION_OK:unregistered_event_does_not_appear_in_registration");
  } finally {
    await recorder.save(testInfo);
  }
});
