import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { setupAuthenticatedSession, setupEventCreationScenario } from "../../helpers/mock-api.js";

test("Event Creation Fails Without Title", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "events_missing_required_title",
    testName: "Event Creation Fails Without Title",
  });

  await recorder.step("Mock authenticated session and events API");
  await setupAuthenticatedSession(page);
  await setupEventCreationScenario(page, {
    initialEvents: [],
    failOnCreate: false,
  });

  await recorder.step("Navigate to /events and open create form");
  await page.goto("/events");
  await page.getByRole("button", { name: "Create New Event" }).click();

  await recorder.step("Leave title empty and fill remaining required fields");
  await page.getByPlaceholder("Summarize event activities...").fill("Discussion forum");
  await page.locator('[name="location"]').fill("Virtual");
  await page.locator('[name="startDate"]').fill("2024-12-01");
  await page.locator('[name="endDate"]').fill("2024-12-02");

  await recorder.step("Submit form and verify client-side validation error");
  await page.getByRole("button", { name: "Publish Event" }).click();
  await expect(page.getByText("Title is required")).toBeVisible();
  await expect(page.getByPlaceholder("Summarize event activities...")).toHaveValue("Discussion forum");
  await expect(page.getByText("No Events Found")).toBeVisible();

  console.log("CODEVALID_TEST_ASSERTION_OK:events_missing_required_title");
  await recorder.save(testInfo);
});
