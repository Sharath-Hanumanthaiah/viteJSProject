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

test("User successfully registers for an upcoming event", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "user_registers_for_valid_event",
    testTitle: "User successfully registers for an upcoming event",
  });

  try {
    await recorder.step("Seed authenticated session and mock active event registration endpoints", async () => {
      await setupAuthenticatedSession(page);
      let registrations = [];
      let postPayload = null;

      await page.route("**/api/events", async (route) => json(route, 200, [validUpcomingEvent]));
      await page.route("**/api/registrations/*", async (route) => json(route, 200, registrations));
      await page.route("**/api/registrations", async (route) => {
        postPayload = route.request().postDataJSON();
        registrations = [successfulRegistration];
        return json(route, 201, successfulRegistration);
      });

      page.__postPayload = () => postPayload;
    });

    await recorder.step("Open Home and fill registration form", async () => {
      await page.goto("/");
      await expect(page.getByText("Registration Active")).toBeVisible();
      await page.locator('[name="name"]').fill("Jane Smith");
      await page.locator('[name="email"]').fill("jane@smith.com");
      await page.locator('[name="phone"]').fill("+1 (555) 000-0000");
    });

    await recorder.step("Submit registration and verify success UI", async () => {
      await page.getByRole("button", { name: /Confirm Registration/ }).click();
      await expect(page.getByText("Attendee registered successfully!")).toBeVisible();
      await expect(page.getByText("1 Total")).toBeVisible();
      await expect(page.getByText("Jane Smith")).toBeVisible();
      await expect(page.getByText("jane@smith.com")).toBeVisible();
    });

    await recorder.step("Assert POST payload data was correct", async () => {
      const payload = await page.evaluate(() => window.__codevalid_noop || null).catch(() => null);
      const captured = page.__postPayload();
      expect(captured).toEqual({
        eventId: validUpcomingEvent.id,
        name: "Jane Smith",
        email: "jane@smith.com",
        phone: "+1 (555) 000-0000",
      });
      expect(payload).toBeNull();
    });

    console.log("CODEVALID_TEST_ASSERTION_OK:user_registers_for_valid_event");
  } finally {
    await recorder.save(testInfo);
  }
});
