import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { setupAuthenticatedSession, setupEventCreationScenario } from "../../helpers/mock-api.js";
import { eventA, eventB, eventC } from "../../mock/mock-data.js";

test("events_listing_sorted_by_date", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "events_listing_sorted_by_date",
    testTitle: "Events are displayed in chronological order by start date",
  });

  try {
    await recorder.step("Seed authenticated session and sorted events response", async () => {
      await setupAuthenticatedSession(page);
      await setupEventCreationScenario(page, {
        initialEvents: [eventA, eventB, eventC],
      });
    });

    await recorder.step("Load Events page", async () => {
      await page.goto("/events");
      await expect(page.getByRole("heading", { name: "Events Management Setup" })).toBeVisible();
      await expect(page.getByText("Event A")).toBeVisible();
      await expect(page.getByText("Event B")).toBeVisible();
      await expect(page.getByText("Event C")).toBeVisible();
    });

    await recorder.step("Verify chronological ordering in rendered cards", async () => {
      const titles = await page.locator("h3.text-lg.font-extrabold").allTextContents();
      expect(titles).toEqual(["Event B", "Event A", "Event C"]);
    });

    console.log("CODEVALID_TEST_ASSERTION_OK:events_listing_sorted_by_date");
  } finally {
    await recorder.save(testInfo);
  }
});
