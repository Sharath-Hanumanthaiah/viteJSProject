import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { setupAuthenticatedSession } from "../../helpers/mock-api.js";

test("User creates an event with all required and optional fields", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "create_event_with_all_fields",
    testTitle: "User creates an event with all required and optional fields",
  });

  const initialEvents = [];
  const createdEvent = {
    id: "event_product_launch",
    title: "Product Launch",
    description: "Join us for the launch of our new product.",
    location: "Conference Center A",
    startDate: "2024-06-10",
    endDate: "2024-06-12",
    registrationCount: 0,
  };

  let events = [...initialEvents];

  try {
    await recorder.step("Set authenticated session and mock event APIs", async () => {
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
        expect(body).toEqual({
          title: "Product Launch",
          description: "Join us for the launch of our new product.",
          location: "Conference Center A",
          startDate: "2024-06-10",
          endDate: "2024-06-12",
        });

        events = [...events, createdEvent].sort(
          (a, b) => new Date(a.startDate) - new Date(b.startDate)
        );

        await route.fulfill({
          status: 201,
          contentType: "application/json",
          body: JSON.stringify(createdEvent),
        });
      });
    });

    await recorder.step("Navigate to Events page", async () => {
      await page.goto("/events");
      await expect(page.getByRole("heading", { name: "Events Management Setup" })).toBeVisible();
    });

    await recorder.step("Open create event form", async () => {
      await page.getByRole("button", { name: "Create New Event" }).click();
      await expect(page.getByRole("heading", { name: "New Event Setup" })).toBeVisible();
    });

    await recorder.step("Enter all event fields", async () => {
      await page.locator('[name="title"]').fill("Product Launch");
      await page.locator('[name="description"]').fill("Join us for the launch of our new product.");
      await page.locator('[name="location"]').fill("Conference Center A");
      await page.locator('[name="startDate"]').fill("2024-06-10");
      await page.locator('[name="endDate"]').fill("2024-06-12");
    });

    await recorder.step("Submit the event form", async () => {
      await page.getByRole("button", { name: "Publish Event" }).click();
    });

    await recorder.step("Verify created event is displayed with all fields", async () => {
      await expect(page.getByText("Event created successfully!")).toBeVisible();
      await expect(page.getByText("Product Launch")).toBeVisible();
      await expect(page.getByText("Join us for the launch of our new product.")).toBeVisible();
      await expect(page.getByText("Conference Center A")).toBeVisible();
      await expect(page.getByText("2024-06-10 to 2024-06-12")).toBeVisible();
      await expect(page.getByText("0 registered")).toBeVisible();
    });

    console.log("CODEVALID_TEST_ASSERTION_OK:create_event_with_all_fields");
  } finally {
    await recorder.save(testInfo);
  }
});
