import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { setupAuthenticatedSession, setupHomeRegistrationScenario } from "../../helpers/mock-api.js";

test("UI handles registration request for non-existent event", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "error_state_on_event_not_found",
    testTitle: "UI handles registration request for non-existent event",
  });

  const events = [
    {
      id: "event_visible_001",
      title: "Visible Event",
      description: "Displayed event while POST simulates missing backend entity.",
      startDate: "2026-01-01",
      endDate: "2099-12-31",
      location: "Phoenix, AZ",
      registrationCount: 0,
    },
  ];

  try {
    await recorder.step("Set authenticated session and not-found registration response", async () => {
      await setupAuthenticatedSession(page);
      await setupHomeRegistrationScenario(page, {
        events,
        registrationsByEventId: {
          event_visible_001: [],
        },
        registerError: {
          status: 404,
          message: "Event not found.",
        },
      });
    });

    await recorder.step("Load Home page and fill registration form", async () => {
      await page.goto("/");
      await page.locator('[name="name"]').fill("Ghost User");
      await page.locator('[name="email"]').fill("ghost@example.com");
      await page.locator('[name="phone"]').fill("+1 (555) 999-0000");
    });

    await recorder.step("Submit registration and verify user-friendly not found error", async () => {
      await page.getByRole("button", { name: "Confirm Registration" }).click();
      await expect(page.getByText("Event not found.")).toBeVisible();
      await expect(page.getByText("0 Total")).toBeVisible();
      await expect(page.getByText("Attendee registered successfully!")).toHaveCount(0);
    });

    console.log("CODEVALID_TEST_ASSERTION_OK:error_state_on_event_not_found");
  } finally {
    await recorder.save(testInfo);
  }
});
