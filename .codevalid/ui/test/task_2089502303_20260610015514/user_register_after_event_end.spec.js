import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { setupAuthenticatedSession, setupHomeRegistrationScenario } from "../../helpers/mock-api.js";

test("User cannot register after event end date", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "user_register_after_event_end",
    testTitle: "User cannot register after event end date",
  });

  const closedEndDate = "2020-01-02";
  const events = [
    {
      id: "event_closed_001",
      title: "Closed Expo",
      description: "This event has already ended.",
      startDate: "2020-01-01",
      endDate: closedEndDate,
      location: "Seattle, WA",
      registrationCount: 1,
    },
  ];

  try {
    await recorder.step("Set authenticated session and closed event scenario", async () => {
      await setupAuthenticatedSession(page);
      await setupHomeRegistrationScenario(page, {
        events,
        registrationsByEventId: {
          event_closed_001: [
            {
              id: "reg_closed_001",
              eventId: "event_closed_001",
              name: "Historic Attendee",
              email: "historic@example.com",
              phone: "+1 (555) 777-0001",
              registeredAt: "2020-01-01T12:00:00.000Z",
            },
          ],
        },
      });
    });

    await recorder.step("Load Home page and verify registration closed state", async () => {
      await page.goto("/");
      await expect(page.getByRole("heading", { name: "Registration Desk" })).toBeVisible();
      await expect(page.getByText("Registration Closed")).toBeVisible();
      await expect(page.getByText(`Registration closed on ${closedEndDate}.`)).toBeVisible();
    });

    await recorder.step("Verify registration form is blocked", async () => {
      await expect(page.locator('[name="name"]')).toBeDisabled();
      await expect(page.locator('[name="email"]')).toBeDisabled();
      await expect(page.locator('[name="phone"]')).toBeDisabled();
      await expect(page.getByRole("button", { name: "Confirm Registration" })).toBeDisabled();
    });

    await recorder.step("Verify count remains unchanged", async () => {
      await expect(page.getByText("1 Total")).toBeVisible();
      await expect(page.getByText("Historic Attendee")).toBeVisible();
      await expect(page.getByText("Attendee registered successfully!")).toHaveCount(0);
    });

    console.log("CODEVALID_TEST_ASSERTION_OK:user_register_after_event_end");
  } finally {
    await recorder.save(testInfo);
  }
});
