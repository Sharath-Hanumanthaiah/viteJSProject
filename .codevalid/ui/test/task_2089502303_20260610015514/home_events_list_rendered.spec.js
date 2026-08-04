import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { setupAuthenticatedSession, setupHomeRegistrationScenario } from "../../helpers/mock-api.js";

test("Events are displayed on the Home page", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "home_events_list_rendered",
    testTitle: "Events are displayed on the Home page",
  });

  const events = [
    {
      id: "event_render_001",
      title: "Tech Conference 2026",
      description: "Annual technology conference covering AI, cloud, and DevOps.",
      startDate: "2026-01-01",
      endDate: "2099-12-31",
      location: "San Francisco, CA",
      registrationCount: 2,
    },
    {
      id: "event_render_002",
      title: "Design Sprint Workshop",
      description: "Hands-on design sprint workshop for product teams.",
      startDate: "2026-02-01",
      endDate: "2099-12-31",
      location: "New York, NY",
      registrationCount: 0,
    },
  ];

  try {
    await recorder.step("Set authenticated session and mock Home page APIs", async () => {
      await setupAuthenticatedSession(page);
      await setupHomeRegistrationScenario(page, {
        events,
        registrationsByEventId: {
          event_render_001: [
            {
              id: "reg_render_001",
              eventId: "event_render_001",
              name: "Alice Johnson",
              email: "alice@example.com",
              phone: "+1 (555) 100-0001",
              registeredAt: "2026-06-01T10:00:00.000Z",
            },
            {
              id: "reg_render_002",
              eventId: "event_render_001",
              name: "Bob Smith",
              email: "bob@example.com",
              phone: "+1 (555) 100-0002",
              registeredAt: "2026-06-02T11:00:00.000Z",
            },
          ],
          event_render_002: [],
        },
      });
    });

    await recorder.step("Load the Home page", async () => {
      await page.goto("/");
      await expect(page.getByRole("heading", { name: "Registration Desk" })).toBeVisible();
    });

    await recorder.step("Observe event data and registration count rendering", async () => {
      await expect(page.getByText("Tech Conference 2026")).toBeVisible();
      await expect(page.getByText("Annual technology conference covering AI, cloud, and DevOps.")).toBeVisible();
      await expect(page.getByText("Design Sprint Workshop")).toBeVisible();
      await expect(page.getByText("Select Active Event")).toBeVisible();
      await expect(page.getByText("Event Dates:")).toBeVisible();
      await expect(page.getByText("2 Total")).toBeVisible();
      await expect(page.getByText("Alice Johnson")).toBeVisible();
      await expect(page.getByText("alice@example.com")).toBeVisible();
      await expect(page.getByText("+1 (555) 100-0001")).toBeVisible();
    });

    console.log("CODEVALID_TEST_ASSERTION_OK:home_events_list_rendered");
  } finally {
    await recorder.save(testInfo);
  }
});
