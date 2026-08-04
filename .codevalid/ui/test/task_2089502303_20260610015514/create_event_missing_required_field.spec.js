import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { setupAuthenticatedSession } from "../../helpers/mock-api.js";

test("User attempts to create an event with a missing required field", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "create_event_missing_required_field",
    testTitle: "User attempts to create an event with a missing required field",
  });

  let events = [];
  let postCalled = false;

  try {
    await recorder.step("Set authenticated session and mock empty events API", async () => {
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
            message: "Title, start date, end date, and location are required.",
          }),
        });
      });
    });

    await recorder.step("Navigate to Events page and open form", async () => {
      await page.goto("/events");
      await page.getByRole("button", { name: "Create New Event" }).click();
      await expect(page.getByRole("heading", { name: "New Event Setup" })).toBeVisible();
    });

    await recorder.step("Enter event data with missing title", async () => {
      await expect(page.locator('[name="title"]')).toHaveValue("");
      await page.locator('[name="location"]').fill("Conference Center A");
      await page.locator('[name="startDate"]').fill("2024-06-10");
      await page.locator('[name="endDate"]').fill("2024-06-12");
    });

    await recorder.step("Submit the event form", async () => {
      await page.getByRole("button", { name: "Publish Event" }).click();
    });

    await recorder.step("Verify client-side validation blocks creation and no new card appears", async () => {
      await expect(page.getByText("Title is required")).toBeVisible();
      expect(postCalled).toBe(false);
      await expect(page.getByRole("heading", { name: "No Events Found" })).toBeVisible();
      await expect(page.getByText("Conference Center A")).toHaveCount(0);
    });

    console.log("CODEVALID_TEST_ASSERTION_OK:create_event_missing_required_field");
  } finally {
    await recorder.save(testInfo);
  }
});
