import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { setupAuthenticatedSession, setupHomeRegistrationScenario } from "../../helpers/mock-api.js";

test("Events with zero registrations show correct count", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "zero_registration_count_displayed",
    testTitle: "Events with zero registrations show correct count",
  });

  const events = [
    {
      id: "event_zero_001",
      title: "Zero Count Event",
      description: "Event with no attendees yet.",
      startDate: "2026-01-01",
      endDate: "2099-12-31",
      location: "Miami, FL",
      registrationCount: 0,
    },
  ];

  try {
    await recorder.step("Set authenticated session and zero-registration event data", async () => {
      await setupAuthenticatedSession(page);
      await setupHomeRegistrationScenario(page, {
        events,
        registrationsByEventId: {
          event_zero_001: [],
        },
      });
    });

    await recorder.step("Load Home page", async () => {
      await page.goto("/");
      await expect(page.getByRole("heading", { name: "Registration Desk" })).toBeVisible();
    });

    await recorder.step("Verify the selected event displays zero registrations clearly", async () => {
      await expect(page.getByText("0 Total")).toBeVisible();
      await expect(page.getByText("No Registered Attendees")).toBeVisible();
      await expect(page.getByText("Zero Count Event")).toBeVisible();
    });

    console.log("CODEVALID_TEST_ASSERTION_OK:zero_registration_count_displayed");
  } finally {
    await recorder.save(testInfo);
  }
});
