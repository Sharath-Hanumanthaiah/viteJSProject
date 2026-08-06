import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { setupAuthenticatedSession, setupEventCreationScenario } from "../../helpers/mock-api.js";
import { annualConferenceEvent } from "../../mock/mock-data.js";

test("event_creation_with_all_fields", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "event_creation_with_all_fields",
    testTitle: "User successfully creates an event with all required and optional fields",
  });

  try {
    await recorder.step("Seed authenticated session and event API mocks", async () => {
      await setupAuthenticatedSession(page);
      await setupEventCreationScenario(page, {
        initialEvents: [],
        createdEvents: [annualConferenceEvent],
      });
    });

    await recorder.step("Navigate to Events page", async () => {
      await page.goto("/events");
      await expect(page.getByRole("heading", { name: "Events Management Setup" })).toBeVisible();
      await expect(page.getByRole("heading", { name: "No Events Found" })).toBeVisible();
    });

    await recorder.step("Open event creation form", async () => {
      await page.getByRole("button", { name: "Create New Event" }).click();
      await expect(page.getByRole("heading", { name: "New Event Setup" })).toBeVisible();
    });

    await recorder.step("Fill all event fields", async () => {
      await page.locator('[name="title"]').fill("Annual Conference");
      await page.locator('[name="description"]').fill("Annual tech event for developers");
      await page.locator('[name="location"]').fill("Convention Center, New York");
      await page.locator('[name="startDate"]').fill("2024-06-15");
      await page.locator('[name="endDate"]').fill("2024-06-17");
    });

    await recorder.step("Submit event creation", async () => {
      await page.getByRole("button", { name: "Publish Event" }).click();
      await expect(page.getByText("Event created successfully!")).toBeVisible();
    });

    await recorder.step("Verify created event is rendered with all fields", async () => {
      await expect(page.getByText("Annual Conference")).toBeVisible();
      await expect(page.getByText("Annual tech event for developers")).toBeVisible();
      await expect(page.getByText("Convention Center, New York")).toBeVisible();
      await expect(page.getByText("2024-06-15 to 2024-06-17")).toBeVisible();
      await expect(page.getByText("0 registered")).toBeVisible();
    });

    console.log("CODEVALID_TEST_ASSERTION_OK:event_creation_with_all_fields");
  } finally {
    await recorder.save(testInfo);
  }
});
