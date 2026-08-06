import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { setupAuthenticatedSession } from "../../helpers/mock-api.js";
import { validUpcomingEvent } from "../../mock/mock-data.js";

function json(route, status, body) {
  return route.fulfill({
    status,
    contentType: "application/json",
    body: JSON.stringify(body),
  });
}

test("Registration fails if event ID is invalid or not found", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "event_not_found_registration",
    testTitle: "Registration fails if event ID is invalid or not found",
  });

  try {
    await recorder.step("Seed authenticated session and mock event-not-found POST failure", async () => {
      await setupAuthenticatedSession(page);
      await page.route("**/api/events", async (route) => json(route, 200, [validUpcomingEvent]));
      await page.route("**/api/registrations/*", async (route) => json(route, 200, []));
      await page.route("**/api/registrations", async (route) => json(route, 404, { message: "Event not found." }));
    });

    await recorder.step("Open Home and tamper the selected event id before submitting", async () => {
      await page.goto("/");
      await page.evaluate(() => {
        const select = document.querySelector("select");
        const option = document.createElement("option");
        option.value = "nonexistent";
        option.textContent = "Ghost Event";
        select.appendChild(option);
        select.value = "nonexistent";
        select.dispatchEvent(new Event("change", { bubbles: true }));
      });
      await page.locator('[name="name"]').fill("Jane Smith");
      await page.locator('[name="email"]').fill("jane@smith.com");
      await page.locator('[name="phone"]').fill("+1 (555) 000-0000");
    });

    await recorder.step("Submit and verify backend not-found error is surfaced", async () => {
      await page.getByRole("button", { name: /Confirm Registration/ }).click();
      await expect(page.getByText("Event not found.")).toBeVisible();
      await expect(page.getByText("0 Total")).toBeVisible();
    });

    console.log("CODEVALID_TEST_ASSERTION_OK:event_not_found_registration");
  } finally {
    await recorder.save(testInfo);
  }
});
