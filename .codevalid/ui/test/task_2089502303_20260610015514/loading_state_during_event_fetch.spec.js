import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { setupAuthenticatedSession, setupHomeRegistrationScenario } from "../../helpers/mock-api.js";

test("UI shows loading state while fetching events", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "loading_state_during_event_fetch",
    testTitle: "UI shows loading state while fetching events",
  });

  const events = [
    {
      id: "event_loading_001",
      title: "Delayed Event",
      description: "Event returned after simulated network delay.",
      startDate: "2026-01-01",
      endDate: "2099-12-31",
      location: "Los Angeles, CA",
      registrationCount: 0,
    },
  ];

  try {
    await recorder.step("Set authenticated session and delay /api/events response", async () => {
      await setupAuthenticatedSession(page);
      await setupHomeRegistrationScenario(page, {
        events,
        registrationsByEventId: {
          event_loading_001: [],
        },
        delayEventsMs: 1200,
      });
    });

    await recorder.step("Load Home page and verify loading indicator appears before data resolves", async () => {
      await page.goto("/");
      await expect(page.getByText("Fetching workspace directories...")).toBeVisible();
    });

    await recorder.step("Verify loading indicator disappears once events are received", async () => {
      await expect(page.getByRole("heading", { name: "Registration Desk" })).toBeVisible();
      await expect(page.getByText("Delayed Event")).toBeVisible();
      await expect(page.getByText("Fetching workspace directories...")).toHaveCount(0);
    });

    console.log("CODEVALID_TEST_ASSERTION_OK:loading_state_during_event_fetch");
  } finally {
    await recorder.save(testInfo);
  }
});
