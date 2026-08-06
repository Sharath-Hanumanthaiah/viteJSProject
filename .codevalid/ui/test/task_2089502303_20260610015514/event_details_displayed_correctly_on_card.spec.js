import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { setupAuthenticatedSession } from "../../helpers/mock-api.js";
import { techSummitEvent } from "../../mock/mock-data.js";

function json(route, status, body) {
  return route.fulfill({
    status,
    contentType: "application/json",
    body: JSON.stringify(body),
  });
}

test("Event card displays all metadata correctly: title, description, location, dates", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "event_details_displayed_correctly_on_card",
    testTitle: "Event card displays all metadata correctly: title, description, location, dates",
  });

  try {
    await recorder.step("Seed authenticated session and mock the single event payload", async () => {
      await setupAuthenticatedSession(page);
      await page.route("**/api/events", async (route) => json(route, 200, [techSummitEvent]));
      await page.route("**/api/registrations/*", async (route) => json(route, 200, []));
    });

    await recorder.step("Open Home and inspect the event metadata", async () => {
      await page.goto("/");
      await expect(page.getByRole("option", { name: "Tech Summit" })).toBeVisible();
      await expect(page.getByText("Annual conference")).toBeVisible();
      await expect(page.getByText("San Francisco")).toBeVisible();
      await expect(page.getByText("2024-06-01")).toBeVisible();
      await expect(page.getByText("2024-06-03")).toBeVisible();
    });

    console.log("CODEVALID_TEST_ASSERTION_OK:event_details_displayed_correctly_on_card");
  } finally {
    await recorder.save(testInfo);
  }
});
