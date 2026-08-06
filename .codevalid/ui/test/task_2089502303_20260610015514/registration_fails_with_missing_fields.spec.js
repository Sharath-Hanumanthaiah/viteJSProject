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

test("Registration fails if required fields are missing", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "registration_fails_with_missing_fields",
    testTitle: "Registration fails if required fields are missing",
  });

  try {
    await recorder.step("Seed authenticated session and mock active event", async () => {
      await setupAuthenticatedSession(page);
      let postCalls = 0;
      await page.route("**/api/events", async (route) => json(route, 200, [validUpcomingEvent]));
      await page.route("**/api/registrations/*", async (route) => json(route, 200, []));
      await page.route("**/api/registrations", async (route) => {
        postCalls += 1;
        return json(route, 400, { message: "Event, name, email, and phone number are required." });
      });
      page.__postCalls = () => postCalls;
    });

    await recorder.step("Open Home and leave the name field empty", async () => {
      await page.goto("/");
      await page.locator('[name="email"]').fill("jane@smith.com");
      await page.locator('[name="phone"]').fill("+1 (555) 000-0000");
    });

    await recorder.step("Submit and verify client-side validation blocks the request", async () => {
      await page.getByRole("button", { name: /Confirm Registration/ }).click();
      await expect(page.getByText("Attendee name is required")).toBeVisible();
      expect(page.__postCalls()).toBe(0);
      await expect(page.getByText("0 Total")).toBeVisible();
    });

    console.log("CODEVALID_TEST_ASSERTION_OK:registration_fails_with_missing_fields");
  } finally {
    await recorder.save(testInfo);
  }
});
