import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { setupAuthenticatedSession } from "../../helpers/mock-api.js";

test("Event card displays accurate registration count from backend", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "event_registration_count_displayed",
    testTitle: "Event card displays accurate registration count from backend",
  });

  const events = [
    {
      id: "event_a",
      title: "Event A",
      description: "Popular event",
      location: "Venue A",
      startDate: "2024-06-10",
      endDate: "2024-06-12",
      registrationCount: 3,
    },
    {
      id: "event_b",
      title: "Event B",
      description: "Smaller event",
      location: "Venue B",
      startDate: "2024-06-20",
      endDate: "2024-06-21",
      registrationCount: 1,
    },
  ];

  try {
    await recorder.step("Set authenticated session and mock events with registration counts", async () => {
      await setupAuthenticatedSession(page);
      await page.route("**/api/events", async (route) => {
        await route.fulfill({
          status: 200,
          contentType: "application/json",
          body: JSON.stringify(events),
        });
      });
    });

    await recorder.step("Load the Events page", async () => {
      await page.goto("/events");
    });

    await recorder.step("Verify registration counts are displayed on event cards", async () => {
      await expect(page.getByText("Event A")).toBeVisible();
      await expect(page.getByText("Event B")).toBeVisible();
      await expect(page.getByText("3 registered")).toBeVisible();
      await expect(page.getByText("1 registered")).toBeVisible();
    });

    console.log("CODEVALID_TEST_ASSERTION_OK:event_registration_count_displayed");
  } finally {
    await recorder.save(testInfo);
  }
});
