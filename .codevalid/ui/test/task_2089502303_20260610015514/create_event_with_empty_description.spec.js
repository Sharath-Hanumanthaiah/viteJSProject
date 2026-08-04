import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { setupAuthenticatedSession } from "../../helpers/mock-api.js";

test("User creates an event with empty description field", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "create_event_with_empty_description",
    testTitle: "User creates an event with empty description field",
  });

  const createdEvent = {
    id: "event_team_retreat",
    title: "Team Retreat",
    description: "",
    location: "Mountain Retreat",
    startDate: "2024-07-01",
    endDate: "2024-07-03",
    registrationCount: 0,
  };

  let events = [];

  try {
    await recorder.step("Set authenticated session and mock event creation API", async () => {
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
          title: "Team Retreat",
          description: "",
          location: "Mountain Retreat",
          startDate: "2024-07-01",
          endDate: "2024-07-03",
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

    await recorder.step("Open event creation form", async () => {
      await page.goto("/events");
      await page.getByRole("button", { name: "Create New Event" }).click();
    });

    await recorder.step("Fill required fields and leave description empty", async () => {
      await page.locator('[name="title"]').fill("Team Retreat");
      await expect(page.locator('[name="description"]')).toHaveValue("");
      await page.locator('[name="location"]').fill("Mountain Retreat");
      await page.locator('[name="startDate"]').fill("2024-07-01");
      await page.locator('[name="endDate"]').fill("2024-07-03");
    });

    await recorder.step("Submit and verify fallback description text", async () => {
      await page.getByRole("button", { name: "Publish Event" }).click();
      await expect(page.getByText("Event created successfully!")).toBeVisible();
      await expect(page.getByText("Team Retreat")).toBeVisible();
      await expect(page.getByText("Mountain Retreat")).toBeVisible();
      await expect(page.getByText("2024-07-01 to 2024-07-03")).toBeVisible();
      await expect(page.getByText("No description provided.")).toBeVisible();
    });

    console.log("CODEVALID_TEST_ASSERTION_OK:create_event_with_empty_description");
  } finally {
    await recorder.save(testInfo);
  }
});
