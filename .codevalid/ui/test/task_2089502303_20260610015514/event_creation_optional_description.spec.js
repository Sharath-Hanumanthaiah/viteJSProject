import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { setupAuthenticatedSession, setupEventCreationScenario } from "../../helpers/mock-api.js";
import { lunchAndLearnEvent } from "../../mock/mock-data.js";

test("event_creation_optional_description", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "event_creation_optional_description",
    testTitle: "Event creation succeeds when description is omitted",
  });

  try {
    await recorder.step("Seed authenticated session and event API mocks", async () => {
      await setupAuthenticatedSession(page);
      await setupEventCreationScenario(page, {
        initialEvents: [],
        createdEvents: [lunchAndLearnEvent],
      });
    });

    await recorder.step("Navigate to Events page and open create form", async () => {
      await page.goto("/events");
      await page.getByRole("button", { name: "Create New Event" }).click();
    });

    await recorder.step("Fill required fields and leave description empty", async () => {
      await page.locator('[name="title"]').fill("Lunch & Learn");
      await expect(page.locator('[name="description"]')).toHaveValue("");
      await page.locator('[name="location"]').fill("Cafeteria");
      await page.locator('[name="startDate"]').fill("2024-07-01");
      await page.locator('[name="endDate"]').fill("2024-07-01");
    });

    await recorder.step("Submit and verify event renders with empty description fallback", async () => {
      await page.getByRole("button", { name: "Publish Event" }).click();
      await expect(page.getByText("Event created successfully!")).toBeVisible();
      await expect(page.getByText("Lunch & Learn")).toBeVisible();
      await expect(page.getByText("Cafeteria")).toBeVisible();
      await expect(page.getByText("2024-07-01 to 2024-07-01")).toBeVisible();
      await expect(page.getByText("No description provided.")).toBeVisible();
    });

    console.log("CODEVALID_TEST_ASSERTION_OK:event_creation_optional_description");
  } finally {
    await recorder.save(testInfo);
  }
});
