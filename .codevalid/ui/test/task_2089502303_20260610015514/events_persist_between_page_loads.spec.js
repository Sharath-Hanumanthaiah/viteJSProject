import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { setupAuthenticatedSession, setupEventCreationScenario } from "../../helpers/mock-api.js";
import { persistedEventOne, persistedEventTwo } from "../../mock/mock-data.js";

test("events_persist_between_page_loads", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "events_persist_between_page_loads",
    testTitle: "Event data persists across page reloads",
  });

  try {
    await recorder.step("Seed authenticated session and persisted event list", async () => {
      await setupAuthenticatedSession(page);
      await setupEventCreationScenario(page, {
        initialEvents: [persistedEventOne, persistedEventTwo],
      });
    });

    await recorder.step("Open Events page and verify stored events", async () => {
      await page.goto("/events");
      await expect(page.getByText("Architecture Review")).toBeVisible();
      await expect(page.getByText("Customer Demo Day")).toBeVisible();
    });

    await recorder.step("Navigate away to Home page", async () => {
      await page.goto("/");
    });

    await recorder.step("Navigate back to Events page and verify persistence", async () => {
      await page.goto("/events");
      await expect(page.getByText("Architecture Review")).toBeVisible();
      await expect(page.getByText("Customer Demo Day")).toBeVisible();
      await expect(page.getByText("2 registered")).toBeVisible();
      await expect(page.getByText("4 registered")).toBeVisible();

      const titles = await page.locator("h3.text-lg.font-extrabold").allTextContents();
      expect(titles).toEqual(["Architecture Review", "Customer Demo Day"]);
    });

    console.log("CODEVALID_TEST_ASSERTION_OK:events_persist_between_page_loads");
  } finally {
    await recorder.save(testInfo);
  }
});
