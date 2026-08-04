import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { setupAuthenticatedSession, setupHomeRegistrationScenario } from "../../helpers/mock-api.js";

test("Registered users are displayed for a selected event", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "registration_list_retrieved_for_event",
    testTitle: "Registered users are displayed for a selected event",
  });

  const events = [
    {
      id: "event_regs_001",
      title: "Community Meetup",
      description: "Event with multiple registrations already stored.",
      startDate: "2026-01-01",
      endDate: "2099-12-31",
      location: "Remote",
      registrationCount: 2,
    },
  ];

  try {
    await recorder.step("Set authenticated session and registrations list scenario", async () => {
      await setupAuthenticatedSession(page);
      await setupHomeRegistrationScenario(page, {
        events,
        registrationsByEventId: {
          event_regs_001: [
            {
              id: "reg_recent_001",
              eventId: "event_regs_001",
              name: "Most Recent User",
              email: "recent@example.com",
              phone: "+1 (555) 444-0002",
              registeredAt: "2026-06-05T12:00:00.000Z",
            },
            {
              id: "reg_older_001",
              eventId: "event_regs_001",
              name: "Earlier User",
              email: "earlier@example.com",
              phone: "+1 (555) 444-0001",
              registeredAt: "2026-06-04T12:00:00.000Z",
            },
          ],
        },
      });
    });

    await recorder.step("Load Home page and wait for registrants retrieval", async () => {
      await page.goto("/");
      await expect(page.getByRole("heading", { name: "Registered Audience" })).toBeVisible();
      await expect(page.getByText("2 Total")).toBeVisible();
    });

    await recorder.step("Verify registrant details are rendered in the list", async () => {
      await expect(page.getByText("Most Recent User")).toBeVisible();
      await expect(page.getByText("recent@example.com")).toBeVisible();
      await expect(page.getByText("+1 (555) 444-0002")).toBeVisible();
      await expect(page.getByText("Earlier User")).toBeVisible();
      await expect(page.getByText("earlier@example.com")).toBeVisible();
      await expect(page.getByText("+1 (555) 444-0001")).toBeVisible();
    });

    console.log("CODEVALID_TEST_ASSERTION_OK:registration_list_retrieved_for_event");
  } finally {
    await recorder.save(testInfo);
  }
});
