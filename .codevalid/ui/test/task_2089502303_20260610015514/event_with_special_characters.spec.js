import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { setupAuthenticatedSession } from "../../helpers/mock-api.js";

test("User creates an event with special characters in title and location", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "event_with_special_characters",
    testTitle: "User creates an event with special characters in title and location",
  });

  const specialEvent = {
    id: "event_special_chars",
    title: "Café & Co 🚀",
    description: "",
    location: "Main hall (Bldg @ 3)",
    startDate: "2024-06-20",
    endDate: "2024-06-21",
    registrationCount: 0,
  };

  let events = [];

  try {
    await recorder.step("Set authenticated session and mock special-character event creation", async () => {
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

        const body = route.request().postDataJSON();
        expect(body.title).toBe("Café & Co 🚀");
        expect(body.location).toBe("Main hall (Bldg @ 3)");

        events = [...events, specialEvent];

        await route.fulfill({
          status: 201,
          contentType: "application/json",
          body: JSON.stringify(specialEvent),
        });
      });
    });

    await recorder.step("Open event creation form", async () => {
      await page.goto("/events");
      await page.getByRole("button", { name: "Create New Event" }).click();
    });

    await recorder.step("Fill form using special characters", async () => {
      await page.locator('[name="title"]').fill("Café & Co 🚀");
      await page.locator('[name="location"]').fill("Main hall (Bldg @ 3)");
      await page.locator('[name="startDate"]').fill("2024-06-20");
      await page.locator('[name="endDate"]').fill("2024-06-21");
    });

    await recorder.step("Submit and verify rendered special characters", async () => {
      await page.getByRole("button", { name: "Publish Event" }).click();
      await expect(page.getByText("Café & Co 🚀")).toBeVisible();
      await expect(page.getByText("Main hall (Bldg @ 3)")).toBeVisible();
      await expect(page.getByText("2024-06-20 to 2024-06-21")).toBeVisible();
    });

    console.log("CODEVALID_TEST_ASSERTION_OK:event_with_special_characters");
  } finally {
    await recorder.save(testInfo);
  }
});
