import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { setupAuthenticatedSession, setupEventCreationScenario } from "../../helpers/mock-api.js";
import { refreshCreatedEvent } from "../../mock/mock-data.js";

test("event_creation_success_refreshes_list", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "event_creation_success_refreshes_list",
    testTitle: "After successful event creation, the event list auto-refreshes to include the new event",
  });

  try {
    await recorder.step("Seed authenticated session and empty initial events", async () => {
      await setupAuthenticatedSession(page);
      await setupEventCreationScenario(page, {
        initialEvents: [],
        createdEvents: [refreshCreatedEvent],
      });
    });

    await recorder.step("Open Events page", async () => {
      await page.goto("/events");
      await expect(page.getByRole("heading", { name: "No Events Found" })).toBeVisible();
    });

    await recorder.step("Create a valid event", async () => {
      await page.getByRole("button", { name: "Create New Event" }).click();
      await page.locator('[name="title"]').fill("Release Planning Session");
      await page.getByPlaceholder("Summarize event activities...").fill("Quarterly roadmap alignment");
      await page.locator('[name="location"]').fill("HQ Board Room");
      await page.locator('[name="startDate"]').fill("2024-08-05");
      await page.locator('[name="endDate"]').fill("2024-08-05");
      await page.getByRole("button", { name: "Publish Event" }).click();
    });

    await recorder.step("Verify new event appears without reload", async () => {
      await expect(page.getByText("Event created successfully!")).toBeVisible();
      await expect(page.getByText("Release Planning Session")).toBeVisible();
      await expect(page.getByText("HQ Board Room")).toBeVisible();
      await expect(page.getByText("2024-08-05 to 2024-08-05")).toBeVisible();
    });

    console.log("CODEVALID_TEST_ASSERTION_OK:event_creation_success_refreshes_list");
  } finally {
    await recorder.save(testInfo);
  }
});
