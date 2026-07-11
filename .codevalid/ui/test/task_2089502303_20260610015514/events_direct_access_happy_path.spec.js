import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { setupAuthenticatedSession, setupEventCreationScenario } from "../../helpers/mock-api.js";

test("Create Event via Direct Access to /events", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "events_direct_access_happy_path",
    testName: "Create Event via Direct Access to /events",
  });

  const initialEvents = [];
  const createdEvent = {
    id: "event-tech-symposium",
    title: "Tech Symposium",
    description: "A conference on emerging technologies",
    location: "Remote/Hybrid",
    startDate: "2024-09-01",
    endDate: "2024-09-03",
    registrationCount: 0,
  };

  await recorder.step("Seed authenticated session and mock event APIs");
  await setupAuthenticatedSession(page);
  await setupEventCreationScenario(page, {
    initialEvents,
    expectedCreatePayload: {
      title: "Tech Symposium",
      description: "A conference on emerging technologies",
      location: "Remote/Hybrid",
      startDate: "2024-09-01",
      endDate: "2024-09-03",
    },
    createdEvent,
  });

  await recorder.step("Navigate directly to /events");
  await page.goto("/events");
  await expect(page.getByRole("heading", { name: "Events Management Setup" })).toBeVisible();

  await recorder.step("Open the create event form");
  await page.getByRole("button", { name: "Create New Event" }).click();
  await expect(page.getByRole("heading", { name: "New Event Setup" })).toBeVisible();

  await recorder.step("Enter event title");
  await page.locator('[name="title"]').fill("Tech Symposium");

  await recorder.step("Enter description");
  await page.getByPlaceholder("Summarize event activities...").fill("A conference on emerging technologies");

  await recorder.step("Enter location");
  await page.locator('[name="location"]').fill("Remote/Hybrid");

  await recorder.step("Enter start date");
  await page.locator('[name="startDate"]').fill("2024-09-01");

  await recorder.step("Enter end date");
  await page.locator('[name="endDate"]').fill("2024-09-03");

  await recorder.step("Submit the event form");
  await page.getByRole("button", { name: "Publish Event" }).click();

  await recorder.step("Verify success state and stored event details");
  await expect(page.getByText("Event created successfully!")).toBeVisible();
  await expect(page.getByText("Tech Symposium")).toBeVisible();
  await expect(page.getByText("A conference on emerging technologies")).toBeVisible();
  await expect(page.getByText("Remote/Hybrid")).toBeVisible();
  await expect(page.getByText("2024-09-01 to 2024-09-03")).toBeVisible();
  await expect(page.getByText("0 registered")).toBeVisible();
  await expect(page.getByText("Title is required")).toHaveCount(0);
  await expect(page.locator('[name="title"]')).toHaveValue("");
  await expect(page.getByPlaceholder("Summarize event activities...")).toHaveValue("");
  await expect(page.locator('[name="location"]')).toHaveValue("");
  await expect(page.locator('[name="startDate"]')).toHaveValue("");
  await expect(page.locator('[name="endDate"]')).toHaveValue("");

  console.log("CODEVALID_TEST_ASSERTION_OK:events_direct_access_happy_path");
  await recorder.save(testInfo);
});
