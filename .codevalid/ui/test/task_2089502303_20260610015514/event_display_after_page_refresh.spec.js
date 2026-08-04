import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { setupAuthenticatedSession } from "../../helpers/mock-api.js";

test("Events persist and are reloaded after browser page refresh", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "event_display_after_page_refresh",
    testTitle: "Events persist and are reloaded after browser page refresh",
  });

  let events = [];
  const persistedEvent = {
    id: "event_refresh_case",
    title: "Refresh Proof Event",
    description: "Should survive reload",
    location: "Main Stage",
    startDate: "2024-06-22",
    endDate: "2024-06-23",
    registrationCount: 0,
  };

  try {
    await recorder.step("Set authenticated session and persistent event mocks", async () => {
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

        events = [...events, persistedEvent].sort(
          (a, b) => new Date(a.startDate) - new Date(b.startDate)
        );

        await route.fulfill({
          status: 201,
          contentType: "application/json",
          body: JSON.stringify(persistedEvent),
        });
      });
    });

    await recorder.step("Create and save an event", async () => {
      await page.goto("/events");
      await page.getByRole("button", { name: "Create New Event" }).click();
      await page.locator('[name="title"]').fill("Refresh Proof Event");
      await page.locator('[name="description"]').fill("Should survive reload");
      await page.locator('[name="location"]').fill("Main Stage");
      await page.locator('[name="startDate"]').fill("2024-06-22");
      await page.locator('[name="endDate"]').fill("2024-06-23");
      await page.getByRole("button", { name: "Publish Event" }).click();
    });

    await recorder.step("Verify event appears before refresh", async () => {
      await expect(page.getByText("Refresh Proof Event")).toBeVisible();
      await expect(page.getByText("Should survive reload")).toBeVisible();
      await expect(page.getByText("Main Stage")).toBeVisible();
    });

    await recorder.step("Reload page and verify event is repopulated from GET API", async () => {
      await page.reload();
      await expect(page.getByText("Refresh Proof Event")).toBeVisible();
      await expect(page.getByText("Should survive reload")).toBeVisible();
      await expect(page.getByText("Main Stage")).toBeVisible();
      await expect(page.getByText("2024-06-22 to 2024-06-23")).toBeVisible();
    });

    console.log("CODEVALID_TEST_ASSERTION_OK:event_display_after_page_refresh");
  } finally {
    await recorder.save(testInfo);
  }
});
