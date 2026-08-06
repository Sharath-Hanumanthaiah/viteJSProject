import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { setupAuthenticatedSession, setupEventCreationScenario } from "../../helpers/mock-api.js";
import { eventX, eventY } from "../../mock/mock-data.js";

test("event_registration_count_displayed", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "event_registration_count_displayed",
    testTitle: "Registration count is displayed for each event card",
  });

  try {
    await recorder.step("Seed authenticated session and events with registration counts", async () => {
      await setupAuthenticatedSession(page);
      await setupEventCreationScenario(page, {
        initialEvents: [eventX, eventY],
      });
    });

    await recorder.step("Load Events page", async () => {
      await page.goto("/events");
      await expect(page.getByText("Event X")).toBeVisible();
      await expect(page.getByText("Event Y")).toBeVisible();
    });

    await recorder.step("Verify registration counts are shown per card", async () => {
      await expect(page.getByText("3 registered")).toBeVisible();
      await expect(page.getByText("1 registered")).toBeVisible();
    });

    console.log("CODEVALID_TEST_ASSERTION_OK:event_registration_count_displayed");
  } finally {
    await recorder.save(testInfo);
  }
});
