import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { setupAuthenticatedSession, setupEventCreationScenario } from "../../helpers/mock-api.js";

test("event_creation_missing_location", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "event_creation_missing_location",
    testTitle: "Event creation fails when location is missing",
  });

  try {
    let postCalls = 0;

    await recorder.step("Seed authenticated session and route mocks", async () => {
      await setupAuthenticatedSession(page);
      await setupEventCreationScenario(page, { initialEvents: [] });
      await page.route("**/api/events", async (route) => {
        if (route.request().method() === "POST") {
          postCalls += 1;
        }
        return route.fallback();
      });
    });

    await recorder.step("Navigate to Events page and open create form", async () => {
      await page.goto("/events");
      await page.getByRole("button", { name: "Create New Event" }).click();
    });

    await recorder.step("Fill all fields except location", async () => {
      await page.locator('[name="title"]').fill("Workshop");
      await page.getByPlaceholder("Summarize event activities...").fill("Description");
      await page.locator('[name="startDate"]').fill("2024-06-15");
      await page.locator('[name="endDate"]').fill("2024-06-17");
    });

    await recorder.step("Submit and verify client validation", async () => {
      await page.getByRole("button", { name: "Publish Event" }).click();
      await expect(page.getByText("Location is required")).toBeVisible();
      await expect(page.getByText("No Events Found")).toBeVisible();
      expect(postCalls).toBe(0);
    });

    console.log("CODEVALID_TEST_ASSERTION_OK:event_creation_missing_location");
  } finally {
    await recorder.save(testInfo);
  }
});
