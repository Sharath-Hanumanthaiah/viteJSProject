import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { setupAuthenticatedSession, setupHomeRegistrationScenario } from "../../helpers/mock-api.js";

test("User successfully registers for an active event", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "user_registers_valid_event",
    testTitle: "User successfully registers for an active event",
  });

  const events = [
    {
      id: "event_active_001",
      title: "Open Registration Summit",
      description: "A currently active event accepting registrations.",
      startDate: "2026-01-01",
      endDate: "2099-12-31",
      location: "Austin, TX",
      registrationCount: 1,
    },
  ];

  try {
    await recorder.step("Set authenticated session and active event registration scenario", async () => {
      await setupAuthenticatedSession(page);
      await setupHomeRegistrationScenario(page, {
        events,
        registrationsByEventId: {
          event_active_001: [
            {
              id: "reg_existing_001",
              eventId: "event_active_001",
              name: "Existing User",
              email: "existing@example.com",
              phone: "+1 (555) 101-0000",
              registeredAt: "2026-06-01T09:00:00.000Z",
            },
          ],
        },
        registerSuccessResponse: {
          id: "reg_new_001",
          eventId: "event_active_001",
          name: "Jane Smith",
          email: "jane@smith.com",
          phone: "+1 (555) 000-0000",
          registeredAt: "2026-06-03T15:30:00.000Z",
        },
      });
    });

    await recorder.step("Load the Home page and verify active registration state", async () => {
      await page.goto("/");
      await expect(page.getByRole("heading", { name: "Registration Desk" })).toBeVisible();
      await expect(page.getByText("Registration Active")).toBeVisible();
      await expect(page.getByText("You can register attendees for this event.")).toBeVisible();
      await expect(page.getByText("1 Total")).toBeVisible();
    });

    await recorder.step("Fill in name, email, and phone", async () => {
      await page.locator('[name="name"]').fill("Jane Smith");
      await page.locator('[name="email"]').fill("jane@smith.com");
      await page.locator('[name="phone"]').fill("+1 (555) 000-0000");
    });

    await recorder.step("Submit registration and verify success state", async () => {
      await page.getByRole("button", { name: "Confirm Registration" }).click();
      await expect(page.getByText("Attendee registered successfully!")).toBeVisible();
      await expect(page.getByText("2 Total")).toBeVisible();
      await expect(page.getByText("Jane Smith")).toBeVisible();
      await expect(page.getByText("jane@smith.com")).toBeVisible();
      await expect(page.locator('[name="name"]')).toHaveValue("");
      await expect(page.locator('[name="email"]')).toHaveValue("");
      await expect(page.locator('[name="phone"]')).toHaveValue("");
      await expect(page.getByText("Existing User")).toBeVisible();
    });

    console.log("CODEVALID_TEST_ASSERTION_OK:user_registers_valid_event");
  } finally {
    await recorder.save(testInfo);
  }
});
