import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../helpers/execution-recorder.js";

const TEST_ID = "events_empty_state_no_events";

async function seedAuthenticatedSession(page) {
  await page.addInitScript(() => {
    localStorage.setItem("token", "simulated-jwt-token-for-user_test1");
    localStorage.setItem(
      "user",
      JSON.stringify({
        id: "user_test1",
        username: "johndoe",
        email: "john@example.com",
        fullName: "John Doe",
      })
    );
  });
}

async function setupScenarioMocks(page) {
  await page.route("**/api/events", async (route) => {
    if (route.request().method() !== "GET") {
      await route.continue();
      return;
    }

    await route.fulfill({
      status: 200,
      contentType: "application/json",
      body: JSON.stringify([]),
    });
  });
}

test("Empty State When No Events Are Available", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder(TEST_ID, "Empty State When No Events Are Available");

  await recorder.step("Seed authenticated session and mock empty events response");
  await seedAuthenticatedSession(page);
  await setupScenarioMocks(page);

  await recorder.step("Navigate directly to the events management page");
  await page.goto("/events");

  await recorder.step("Verify empty-state content renders without registration actions");
  await expect(page.getByRole("heading", { name: "Events Management Setup" })).toBeVisible();
  await expect(page.getByRole("heading", { name: "No Events Found" })).toBeVisible();
  await expect(page.getByText('Configure your first event schedules by clicking the "Create New Event" button.')).toBeVisible();
  await expect(page.getByRole("button", { name: "Create New Event" })).toBeVisible();
  await expect(page.getByRole("button", { name: /Register/i })).toHaveCount(0);

  console.log(`CODEVALID_TEST_ASSERTION_OK:${TEST_ID}`);
  await recorder.save(testInfo);
});
