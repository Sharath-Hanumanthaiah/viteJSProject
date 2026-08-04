import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { setupAuthenticatedSession } from "../../helpers/mock-api.js";

test("Empty state is shown when no events exist", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "no_events_displayed",
    testTitle: "Empty state is shown when no events exist",
  });

  try {
    await recorder.step("Set authenticated session and mock no events", async () => {
      await setupAuthenticatedSession(page);
      await page.route("**/api/events", async (route) => {
        await route.fulfill({
          status: 200,
          contentType: "application/json",
          body: JSON.stringify([]),
        });
      });
    });

    await recorder.step("Load the Events page", async () => {
      await page.goto("/events");
      await expect(page.getByRole("heading", { name: "Events Management Setup" })).toBeVisible();
    });

    await recorder.step("Verify clear empty state and event creation affordance", async () => {
      await expect(page.getByRole("heading", { name: "No Events Found" })).toBeVisible();
      await expect(
        page.getByText('Configure your first event schedules by clicking the "Create New Event" button.')
      ).toBeVisible();
      await expect(page.getByRole("button", { name: "Create New Event" })).toBeVisible();
    });

    console.log("CODEVALID_TEST_ASSERTION_OK:no_events_displayed");
  } finally {
    await recorder.save(testInfo);
  }
});
