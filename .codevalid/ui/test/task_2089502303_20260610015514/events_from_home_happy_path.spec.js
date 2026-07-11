import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { setupAuthenticatedSession, setupEventCreationScenario, mockHomePageApis } from "../../helpers/mock-api.js";

test("Create Event via Navigation from Home Page", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "events_from_home_happy_path",
    testName: "Create Event via Navigation from Home Page",
  });

  const initialEvents = [];
  const createdEvent = {
    id: "event-annual-summit",
    title: "Annual Summit",
    description: "Industry leaders gathering",
    location: "San Francisco",
    startDate: "2024-10-15",
    endDate: "2024-10-17",
    registrationCount: 0,
  };

  await recorder.step("Mock home page and event APIs");
  await setupAuthenticatedSession(page);
  await mockHomePageApis(page, { upcomingEvents: [] });
  await setupEventCreationScenario(page, {
    initialEvents,
    expectedCreatePayload: {
      title: "Annual Summit",
      description: "Industry leaders gathering",
      location: "San Francisco",
      startDate: "2024-10-15",
      endDate: "2024-10-17",
    },
    createdEvent,
  });

  await recorder.step("Navigate to home page");
  await page.goto("/");

  await recorder.step("Navigate from home page to events page");
  const eventsNav = page.getByRole("link", { name: "Events Setup" }).first();
  await expect(eventsNav).toBeVisible();
  await eventsNav.click();
  await expect(page).toHaveURL(/\/events$/);

  await recorder.step("Open the create event form");
  await page.getByRole("button", { name: "Create New Event" }).click();

  await recorder.step("Enter event details");
  await page.locator('[name="title"]').fill("Annual Summit");
  await page.getByPlaceholder("Summarize event activities...").fill("Industry leaders gathering");
  await page.locator('[name="location"]').fill("San Francisco");
  await page.locator('[name="startDate"]').fill("2024-10-15");
  await page.locator('[name="endDate"]').fill("2024-10-17");

  await recorder.step("Submit the event form");
  await page.getByRole("button", { name: "Publish Event" }).click();

  await recorder.step("Verify the event appears and form resets");
  await expect(page.getByText("Event created successfully!")).toBeVisible();
  await expect(page.getByText("Annual Summit")).toBeVisible();
  await expect(page.getByText("Industry leaders gathering")).toBeVisible();
  await expect(page.getByText("San Francisco")).toBeVisible();
  await expect(page.getByText("2024-10-15 to 2024-10-17")).toBeVisible();
  await expect(page.getByText("0 registered")).toBeVisible();
  await expect(page.getByText("Title is required")).toHaveCount(0);
  await expect(page.locator('[name="title"]')).toHaveValue("");
  await expect(page.getByPlaceholder("Summarize event activities...")).toHaveValue("");
  await expect(page.locator('[name="location"]')).toHaveValue("");
  await expect(page.locator('[name="startDate"]')).toHaveValue("");
  await expect(page.locator('[name="endDate"]')).toHaveValue("");

  console.log("CODEVALID_TEST_ASSERTION_OK:events_from_home_happy_path");
  await recorder.save(testInfo);
});
