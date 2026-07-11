import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { setupAuthenticatedSession, setupEventCreationScenario } from "../../helpers/mock-api.js";

test("Event Creation Fails When End Date Precedes Start Date", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "events_invalid_date_range",
    testName: "Event Creation Fails When End Date Precedes Start Date",
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

  await recorder.step("Enter event details with invalid date range");
  await page.locator('[name="title"]').fill("Holiday Party");
  await page.getByPlaceholder("Summarize event activities...").fill("Year-end celebration");
  await page.locator('[name="location"]').fill("Office");
  await page.locator('[name="startDate"]').fill("2024-12-31");
  await page.locator('[name="endDate"]').fill("2024-12-25");

  await recorder.step("Submit form and verify date validation error");
  await page.getByRole("button", { name: "Publish Event" }).click();
  await expect(page.getByText("End date must be after or equal to start date")).toBeVisible();
  await expect(page.locator('[name="title"]')).toHaveValue("Holiday Party");
  await expect(page.getByText("No Events Found")).toBeVisible();

  console.log("CODEVALID_TEST_ASSERTION_OK:events_invalid_date_range");
  await recorder.save(testInfo);
});
