import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { setupAuthenticatedSession } from "../../helpers/mock-api.js";
import { validUpcomingEvent, successfulRegistration } from "../../mock/mock-data.js";

function json(route, status, body) {
  return route.fulfill({
    status,
    contentType: "application/json",
    body: JSON.stringify(body),
  });
}

test("Successful registration immediately updates UI registration count", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "registration_success_updates_ui",
    testTitle: "Successful registration immediately updates UI registration count",
  });

  try {
    await recorder.step("Seed authenticated session and success registration mocks", async () => {
      await setupAuthenticatedSession(page);
      let registrations = [];
      await page.route("**/api/events", async (route) => json(route, 200, [validUpcomingEvent]));
      await page.route("**/api/registrations/*", async (route) => json(route, 200, registrations));
      await page.route("**/api/registrations", async (route) => {
        registrations = [successfulRegistration];
        return json(route, 201, successfulRegistration);
      });
    });

    await recorder.step("Open Home and confirm initial count is zero", async () => {
      await page.goto("/");
      await expect(page.getByText("0 Total")).toBeVisible();
      await page.locator('[name="name"]').fill("Jane Smith");
      await page.locator('[name="email"]').fill("jane@smith.com");
      await page.locator('[name="phone"]').fill("+1 (555) 000-0000");
    });

    await recorder.step("Submit registration and verify count updates without refresh", async () => {
      await page.getByRole("button", { name: /Confirm Registration/ }).click();
      await expect(page.getByText("Attendee registered successfully!")).toBeVisible();
      await expect(page.getByText("1 Total")).toBeVisible();
      await expect(page.getByText("Jane Smith")).toBeVisible();
    });

    console.log("CODEVALID_TEST_ASSERTION_OK:registration_success_updates_ui");
  } finally {
    await recorder.save(testInfo);
  }
});
