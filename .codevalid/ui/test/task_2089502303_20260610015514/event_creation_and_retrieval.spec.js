import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { setupAuthenticatedSession } from "../../helpers/mock-api.js";
import { emptyEvents, createdSpringHackathonEvent } from "../../mock/mock-data.js";

function json(route, status, body) {
  return route.fulfill({
    status,
    contentType: "application/json",
    body: JSON.stringify(body),
  });
}

test("User creates an event and it appears in the event list", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "event_creation_and_retrieval",
    testTitle: "User creates an event and it appears in the event list",
  });

  try {
    await recorder.step("Seed authenticated session and mock event creation flow", async () => {
      await setupAuthenticatedSession(page);
      let eventsState = [...emptyEvents];

      await page.route("**/api/events", async (route) => {
        const method = route.request().method();
        if (method === "GET") {
          return json(route, 200, [...eventsState]);
        }
        if (method === "POST") {
          eventsState = [createdSpringHackathonEvent];
          return json(route, 201, createdSpringHackathonEvent);
        }
        return route.fallback();
      });

      await page.route("**/api/registrations/*", async (route) => json(route, 200, []));
    });

    await recorder.step("Open the Events page and reveal the creation form", async () => {
      await page.goto("/events");
      await expect(page.getByRole("heading", { name: "Events Management Setup" })).toBeVisible();
      await page.getByRole("button", { name: "Create New Event" }).click();
      await expect(page.locator('[name="title"]')).toBeVisible();
    });

    await recorder.step("Fill the event form with valid values", async () => {
      await page.locator('[name="title"]').fill("Spring Hackathon 2026");
      await page.locator('[name="description"]').fill("Build and demo event prototypes over two days.");
      await page.locator('[name="location"]').fill("Auditorium A");
      await page.locator('[name="startDate"]').fill("2026-06-11");
      await page.locator('[name="endDate"]').fill("2026-06-18");
    });

    await recorder.step("Submit the new event and confirm local UI success", async () => {
      await page.getByRole("button", { name: "Publish Event" }).click();
      await expect(page.getByText("Event created successfully!")).toBeVisible();
      await expect(page.getByText("Spring Hackathon 2026")).toBeVisible();
      await expect(page.getByText("Build and demo event prototypes over two days.")).toBeVisible();
      await expect(page.getByText("Auditorium A")).toBeVisible();
      await expect(page.getByText("2026-06-11 to 2026-06-18")).toBeVisible();
      await expect(page.getByText("0 registered")).toBeVisible();
    });

    await recorder.step("Navigate to Home and verify the created event is retrievable", async () => {
      await page.goto("/");
      await expect(page.getByRole("heading", { name: "Registration Desk" })).toBeVisible();
      await expect(page.getByRole("option", { name: "Spring Hackathon 2026" })).toBeVisible();
      await expect(page.getByText("No Registered Attendees")).toBeVisible();
      await expect(page.getByText("0 Total")).toBeVisible();
      await expect(page.getByText("Registration Upcoming")).toBeVisible();
    });

    console.log("CODEVALID_TEST_ASSERTION_OK:event_creation_and_retrieval");
  } finally {
    await recorder.save(testInfo);
  }
});
