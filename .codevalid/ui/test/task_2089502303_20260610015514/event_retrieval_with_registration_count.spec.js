import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { setupAuthenticatedSession } from "../../helpers/mock-api.js";
import { eventAZeroRegistrations, eventBThreeRegistrations } from "../../mock/mock-data.js";

function json(route, status, body) {
  return route.fulfill({
    status,
    contentType: "application/json",
    body: JSON.stringify(body),
  });
}

test("Event list correctly displays registration count for each event", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "event_retrieval_with_registration_count",
    testTitle: "Event list correctly displays registration count for each event",
  });

  try {
    await recorder.step("Seed authenticated session and mock event list with counts", async () => {
      await setupAuthenticatedSession(page);
      await page.route("**/api/events", async (route) =>
        json(route, 200, [eventAZeroRegistrations, eventBThreeRegistrations])
      );
      await page.route("**/api/registrations/*", async (route) => {
        const url = route.request().url();
        if (url.includes(eventBThreeRegistrations.id)) {
          return json(route, 200, [
            { id: "reg_b001", eventId: eventBThreeRegistrations.id, name: "Reg 1", email: "r1@example.com", phone: "+1 (555) 001-0001", registeredAt: "2026-01-01T10:00:00.000Z" },
            { id: "reg_b002", eventId: eventBThreeRegistrations.id, name: "Reg 2", email: "r2@example.com", phone: "+1 (555) 001-0002", registeredAt: "2026-01-02T10:00:00.000Z" },
            { id: "reg_b003", eventId: eventBThreeRegistrations.id, name: "Reg 3", email: "r3@example.com", phone: "+1 (555) 001-0003", registeredAt: "2026-01-03T10:00:00.000Z" },
          ]);
        }
        return json(route, 200, []);
      });
    });

    await recorder.step("Load the Home page", async () => {
      await page.goto("/");
      await expect(page.getByRole("heading", { name: "Registration Desk" })).toBeVisible();
    });

    await recorder.step("Verify both event options and visible registration count details", async () => {
      await expect(page.locator("select").locator("option", { hasText: "Event A" })).toBeAttached();
      await expect(page.locator("select").locator("option", { hasText: "Event B" })).toBeAttached();
      await expect(page.getByText("Event Dates: ")).toBeVisible();
      await expect(page.getByText("0 Total")).toBeVisible();

      await page.selectOption("select", eventBThreeRegistrations.id);
      await expect(page.getByText("3 Total")).toBeVisible();
    });

    console.log("CODEVALID_TEST_ASSERTION_OK:event_retrieval_with_registration_count");
  } finally {
    await recorder.save(testInfo);
  }
});
