import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { setupAuthenticatedSession, setupHomeRegistrationScenario } from "../../helpers/mock-api.js";

test("User cannot register twice with same email for same event", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "user_duplicated_registration",
    testTitle: "User cannot register twice with same email for same event",
  });

  const events = [
    {
      id: "event_dup_001",
      title: "Duplicate Check Forum",
      description: "Active event used for duplicate registration validation.",
      startDate: "2026-01-01",
      endDate: "2099-12-31",
      location: "Denver, CO",
      registrationCount: 1,
    },
  ];

  try {
    await recorder.step("Set authenticated session and duplicate registration API behavior", async () => {
      await setupAuthenticatedSession(page);
      await setupHomeRegistrationScenario(page, {
        events,
        registrationsByEventId: {
          event_dup_001: [
            {
              id: "reg_dup_001",
              eventId: "event_dup_001",
              name: "Prior Registrant",
              email: "duplicate@example.com",
              phone: "+1 (555) 333-0001",
              registeredAt: "2026-06-01T08:00:00.000Z",
            },
          ],
        },
        registerError: {
          status: 400,
          message: "This email is already registered for this event.",
        },
      });
    });

    await recorder.step("Load Home page and fill duplicate registration details", async () => {
      await page.goto("/");
      await expect(page.getByText("Registration Active")).toBeVisible();
      await page.locator('[name="name"]').fill("Prior Registrant");
      await page.locator('[name="email"]').fill("duplicate@example.com");
      await page.locator('[name="phone"]').fill("+1 (555) 333-0001");
    });

    await recorder.step("Submit and verify duplicate registration error", async () => {
      await page.getByRole("button", { name: "Confirm Registration" }).click();
      await expect(page.getByText("This email is already registered for this event.")).toBeVisible();
      await expect(page.getByText("1 Total")).toBeVisible();
      await expect(page.getByText("Attendee registered successfully!")).toHaveCount(0);
      await expect(page.locator('[name="email"]')).toHaveValue("duplicate@example.com");
    });

    console.log("CODEVALID_TEST_ASSERTION_OK:user_duplicated_registration");
  } finally {
    await recorder.save(testInfo);
  }
});
