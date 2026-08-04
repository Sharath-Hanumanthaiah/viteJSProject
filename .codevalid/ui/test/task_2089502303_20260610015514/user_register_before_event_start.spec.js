import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { setupAuthenticatedSession, setupHomeRegistrationScenario } from "../../helpers/mock-api.js";

test("User cannot register before event start date", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "user_register_before_event_start",
    testTitle: "User cannot register before event start date",
  });

  const futureStartDate = "2099-12-31";
  const events = [
    {
      id: "event_future_001",
      title: "Future Kickoff",
      description: "Registration has not opened yet.",
      startDate: futureStartDate,
      endDate: "2100-01-02",
      location: "Chicago, IL",
      registrationCount: 0,
    },
  ];

  try {
    await recorder.step("Set authenticated session and future event scenario", async () => {
      await setupAuthenticatedSession(page);
      await setupHomeRegistrationScenario(page, {
        events,
        registrationsByEventId: {
          event_future_001: [],
        },
      });
    });

    await recorder.step("Load Home page and verify upcoming registration state", async () => {
      await page.goto("/");
      await expect(page.getByRole("heading", { name: "Registration Desk" })).toBeVisible();
      await expect(page.getByText("Registration Upcoming")).toBeVisible();
      await expect(page.getByText(`Registration opens on ${futureStartDate}.`)).toBeVisible();
    });

    await recorder.step("Attempt to fill registration fields while event is not yet open", async () => {
      await expect(page.locator('[name="name"]')).toBeDisabled();
      await expect(page.locator('[name="email"]')).toBeDisabled();
      await expect(page.locator('[name="phone"]')).toBeDisabled();
      await expect(page.getByRole("button", { name: "Confirm Registration" })).toBeDisabled();
    });

    await recorder.step("Verify no registration is created and count remains unchanged", async () => {
      await expect(page.getByText("No Registered Attendees")).toBeVisible();
      await expect(page.getByText("0 Total")).toBeVisible();
      await expect(page.getByText("Attendee registered successfully!")).toHaveCount(0);
    });

    console.log("CODEVALID_TEST_ASSERTION_OK:user_register_before_event_start");
  } finally {
    await recorder.save(testInfo);
  }
});
