import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";

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

  await page.route("**/api/registrations/**", async (route) => {
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

  await recorder.step("Seed authenticated session and register empty events mocks");
  await seedAuthenticatedSession(page);
  await setupScenarioMocks(page);

  await recorder.step("Navigate directly to the protected registration page");
  await page.goto("/");

  await recorder.step("Verify empty state renders without registration controls");
  await expect(page.getByRole("heading", { name: "No Active Events" })).toBeVisible();
  await expect(page.getByText("You must create an event before registering any user.")).toBeVisible();
  await expect(page.getByRole("button", { name: "Go to Events Setup" })).toBeVisible();
  await expect(page.getByRole("button", { name: /Confirm Registration/i })).toHaveCount(0);
  await expect(page.getByRole("combobox")).toHaveCount(0);

  await recorder.step("Navigate to the events setup page from the empty state CTA");
  await page.getByRole("button", { name: "Go to Events Setup" }).click();
  await expect(page).toHaveURL(/\/events$/);
  await expect(page.getByRole("heading", { name: "Events Management Setup" })).toBeVisible();
  await expect(page.getByRole("heading", { name: "No Events Found" })).toBeVisible();
  await expect(page.getByRole("button", { name: /Create New Event/i })).toBeVisible();

  console.log(`CODEVALID_TEST_ASSERTION_OK:${TEST_ID}`);
  await recorder.save(testInfo);
});
