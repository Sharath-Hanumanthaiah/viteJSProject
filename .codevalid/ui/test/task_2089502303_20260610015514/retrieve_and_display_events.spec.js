import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { setupAuthenticatedSession } from "../../helpers/mock-api.js";

test("Stored events are retrieved and displayed sorted by start date", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "retrieve_and_display_events",
    testTitle: "Stored events are retrieved and displayed sorted by start date",
  });

  const events = [
    {
      id: "event_later",
      title: "Later Summit",
      description: "Second chronologically",
      location: "Hall B",
      startDate: "2024-08-15",
      endDate: "2024-08-16",
      registrationCount: 1,
    },
    {
      id: "event_earlier",
      title: "Earlier Kickoff",
      description: "First chronologically",
      location: "Hall A",
      startDate: "2024-06-01",
      endDate: "2024-06-02",
      registrationCount: 0,
    },
  ].sort((a, b) => new Date(a.startDate) - new Date(b.startDate));

  try {
    await recorder.step("Set authenticated session and mock events retrieval", async () => {
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
      await expect(page.getByRole("heading", { name: "Events Management Setup" })).toBeVisible();
    });

    await recorder.step("Verify events render in ascending start-date order", async () => {
      const titles = page.locator("h3.text-lg");
      await expect(titles.nth(0)).toHaveText("Earlier Kickoff");
      await expect(titles.nth(1)).toHaveText("Later Summit");
      await expect(page.getByText("Hall A")).toBeVisible();
      await expect(page.getByText("2024-06-01 to 2024-06-02")).toBeVisible();
      await expect(page.getByText("Hall B")).toBeVisible();
      await expect(page.getByText("2024-08-15 to 2024-08-16")).toBeVisible();
    });

    console.log("CODEVALID_TEST_ASSERTION_OK:retrieve_and_display_events");
  } finally {
    await recorder.save(testInfo);
  }
});
