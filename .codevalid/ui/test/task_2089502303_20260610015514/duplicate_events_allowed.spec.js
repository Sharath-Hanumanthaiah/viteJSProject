import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { setupAuthenticatedSession } from "../../helpers/mock-api.js";

test("System allows creation of events with identical titles and dates", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "duplicate_events_allowed",
    testTitle: "System allows creation of events with identical titles and dates",
  });

  let events = [];
  let createCount = 0;

  try {
    await recorder.step("Set authenticated session and stateful event mocks", async () => {
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

        createCount += 1;
        const body = route.request().postDataJSON();
        const created = {
          id: `event_weekly_meeting_${createCount}`,
          ...body,
          registrationCount: 0,
        };
        events = [...events, created].sort(
          (a, b) => new Date(a.startDate) - new Date(b.startDate)
        );

        await route.fulfill({
          status: 201,
          contentType: "application/json",
          body: JSON.stringify(created),
        });
      });
    });

    await recorder.step("Navigate to Events page and open form", async () => {
      await page.goto("/events");
      await page.getByRole("button", { name: "Create New Event" }).click();
    });

    await recorder.step("Create first event", async () => {
      await page.locator('[name="title"]').fill("Weekly Meeting");
      await page.locator('[name="location"]').fill("Room 1");
      await page.locator('[name="startDate"]').fill("2024-06-10");
      await page.locator('[name="endDate"]').fill("2024-06-10");
      await page.getByRole("button", { name: "Publish Event" }).click();
      await expect(page.getByText("Event created successfully!")).toBeVisible();
    });

    await recorder.step("Reopen form and create duplicate event", async () => {
      await page.getByRole("button", { name: "Create New Event" }).click();
      await page.locator('[name="title"]').fill("Weekly Meeting");
      await page.locator('[name="location"]').fill("Room 1");
      await page.locator('[name="startDate"]').fill("2024-06-10");
      await page.locator('[name="endDate"]').fill("2024-06-10");
      await page.getByRole("button", { name: "Publish Event" }).click();
      await expect(page.getByText("Event created successfully!")).toBeVisible();
    });

    await recorder.step("Refresh page and verify both duplicate cards remain visible", async () => {
      await page.reload();
      await expect(page.getByText("Weekly Meeting")).toHaveCount(2);
      await expect(page.getByText("Room 1")).toHaveCount(2);
      await expect(page.getByText("2024-06-10 to 2024-06-10")).toHaveCount(2);
    });

    console.log("CODEVALID_TEST_ASSERTION_OK:duplicate_events_allowed");
  } finally {
    await recorder.save(testInfo);
  }
});
