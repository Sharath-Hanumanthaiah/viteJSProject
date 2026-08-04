import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { setupAuthenticatedSession } from "../../helpers/mock-api.js";

test("User attempts to create an event with start date after end date", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "create_event_start_date_after_end_date",
    testTitle: "User attempts to create an event with start date after end date",
  });

  let events = [];
  let postCalled = false;

  try {
    await recorder.step("Set authenticated session and mock events API", async () => {
      await setupAuthenticatedSession(page);
      await page.route("**/api/events", async (route) => {
        if (route.request().method() === "GET") {
          await route.fulfill({
            status: 200,
            contentType: "application/json",
            body: JSON.stringify(events),
          });
          return;
        }

        postCalled = true;
        await route.fulfill({
          status: 400,
          contentType: "application/json",
          body: JSON.stringify({
            message: "Start date must be before or equal to the end date.",
          }),
        });
      });
    });

    await recorder.step("Navigate to Events page and open form", async () => {
      await page.goto("/events");
      await page.getByRole("button", { name: "Create New Event" }).click();
    });

    await recorder.step("Enter start date after end date", async () => {
      await page.locator('[name="title"]').fill("Conference");
      await page.locator('[name="location"]').fill("Conference Center B");
      await page.locator('[name="startDate"]').fill("2024-06-15");
      await page.locator('[name="endDate"]').fill("2024-06-10");
    });

    await recorder.step("Submit the event form", async () => {
      await page.getByRole("button", { name: "Publish Event" }).click();
    });

    await recorder.step("Verify validation error and no event created", async () => {
      await expect(page.getByText("End date must be after or equal to start date")).toBeVisible();
      expect(postCalled).toBe(false);
      await expect(page.getByText("Conference")).toHaveCount(0);
      await expect(page.getByRole("heading", { name: "No Events Found" })).toBeVisible();
    });

    console.log("CODEVALID_TEST_ASSERTION_OK:create_event_start_date_after_end_date");
  } finally {
    await recorder.save(testInfo);
  }
});
