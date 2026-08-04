import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { setupAuthenticatedSession, setupHomeRegistrationScenario } from "../../helpers/mock-api.js";

test("User cannot register with incomplete form data", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "user_register_with_missing_fields",
    testTitle: "User cannot register with incomplete form data",
  });

  const events = [
    {
      id: "event_missing_001",
      title: "Validation Workshop",
      description: "Active event for client-side validation checks.",
      startDate: "2026-01-01",
      endDate: "2099-12-31",
      location: "Boston, MA",
      registrationCount: 0,
    },
  ];

  try {
    await recorder.step("Set authenticated session and active event", async () => {
      await setupAuthenticatedSession(page);
      await setupHomeRegistrationScenario(page, {
        events,
        registrationsByEventId: {
          event_missing_001: [],
        },
      });
    });

    await recorder.step("Load Home page and leave email empty", async () => {
      await page.goto("/");
      await expect(page.getByText("Registration Active")).toBeVisible();
      await page.locator('[name="name"]').fill("Jane Smith");
      await page.locator('[name="phone"]').fill("+1 (555) 000-0000");
      await expect(page.locator('[name="email"]')).toHaveValue("");
    });

    await recorder.step("Submit incomplete form and verify validation feedback", async () => {
      await page.getByRole("button", { name: "Confirm Registration" }).click();
      await expect(page.getByText("Email is required")).toBeVisible();
      await expect(page.getByText("0 Total")).toBeVisible();
      await expect(page.getByText("Attendee registered successfully!")).toHaveCount(0);
      await expect(page.locator('[name="name"]')).toHaveValue("Jane Smith");
      await expect(page.locator('[name="phone"]')).toHaveValue("+1 (555) 000-0000");
    });

    console.log("CODEVALID_TEST_ASSERTION_OK:user_register_with_missing_fields");
  } finally {
    await recorder.save(testInfo);
  }
});
