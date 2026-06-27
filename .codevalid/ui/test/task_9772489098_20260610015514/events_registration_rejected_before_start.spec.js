import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../helpers/execution-recorder.js";

const TEST_ID = "events_registration_rejected_before_start";
const EVENT_ID = "event_before_start";
const FIXED_ISO = "2024-06-05T12:00:00.000Z";

const eventRecord = {
  id: EVENT_ID,
  title: "Summer Innovation Summit",
  description: "Registration opens later",
  startDate: "2024-06-10",
  endDate: "2024-06-20",
  location: "Hall A",
  registrationCount: 2,
};

const initialRegistrations = [
  {
    id: "reg-existing-2",
    eventId: EVENT_ID,
    name: "Morgan Lee",
    email: "morgan@example.com",
    phone: "+1 (555) 222-1111",
    registeredAt: "2024-06-14T10:00:00.000Z",
  },
  {
    id: "reg-existing-1",
    eventId: EVENT_ID,
    name: "Jordan Kim",
    email: "jordan@example.com",
    phone: "+1 (555) 111-2222",
    registeredAt: "2024-06-13T09:00:00.000Z",
  },
];

async function freezeTime(page, isoString) {
  await page.addInitScript(({ fixedNow }) => {
    const RealDate = Date;
    class MockDate extends RealDate {
      constructor(...args) {
        if (args.length === 0) {
          super(fixedNow);
        } else {
          super(...args);
        }
      }
      static now() {
        return new RealDate(fixedNow).getTime();
      }
      static parse(value) {
        return RealDate.parse(value);
      }
      static UTC(...args) {
        return RealDate.UTC(...args);
      }
    }
    window.Date = MockDate;
  }, { fixedNow: isoString });
}

async function seedAuthenticatedSession(page) {
  await page.addInitScript(() => {
    localStorage.setItem("token", "simulated-jwt-token-for-user_test1");
    localStorage.setItem(
      "user",
      JSON.stringify({
        id: "user_test1",
        username: "johndoe",
        email: "john@example.com",
        fullName: "John Doe",
      })
    );
  });
}

async function setupScenarioMocks(page) {
  await page.route("**/api/events", async (route) => {
    if (route.request().method() !== "GET") {
      await route.continue();
      return;
    }

    await route.fulfill({
      status: 200,
      contentType: "application/json",
      body: JSON.stringify([eventRecord]),
    });
  });

  await page.route(`**/api/registrations/${EVENT_ID}`, async (route) => {
    if (route.request().method() !== "GET") {
      await route.continue();
      return;
    }

    await route.fulfill({
      status: 200,
      contentType: "application/json",
      body: JSON.stringify(initialRegistrations),
    });
  });

  await page.route("**/api/registrations", async (route) => {
    if (route.request().method() !== "POST") {
      await route.continue();
      return;
    }

    await route.fulfill({
      status: 400,
      contentType: "application/json",
      body: JSON.stringify({
        message: "Registration has not opened yet. Registration opens on 2024-06-10.",
      }),
    });
  });
}

test("Registration Blocked When Current Date Is Before Event Start", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder(TEST_ID, "Registration Blocked When Current Date Is Before Event Start");

  await recorder.step("Freeze browser date to 2024-06-05 and seed authenticated session");
  await freezeTime(page, FIXED_ISO);
  await seedAuthenticatedSession(page);

  await recorder.step("Register mocked APIs for event and attendees before navigating from signup entry point");
  await setupScenarioMocks(page);

  await recorder.step("Navigate to /signup then proceed to the protected registration page");
  await page.goto("/signup");
  await expect(page).toHaveURL(/\/signup$/);
  await page.goto("/");

  await expect(page.getByRole("heading", { name: "Registration Desk" })).toBeVisible();
  await expect(page.getByText("Registration Upcoming")).toBeVisible();
  await expect(page.getByText("Registration opens on 2024-06-10.")).toBeVisible();
  await expect(page.getByRole("button", { name: /Confirm Registration/i })).toBeDisabled();
  await expect(page.getByPlaceholder("Jane Smith")).toBeDisabled();
  await expect(page.getByPlaceholder("jane@smith.com")).toBeDisabled();
  await expect(page.getByPlaceholder("+1 \(555\) 000-0000")).toBeDisabled();
  await expect(page.getByText("2 Total")).toBeVisible();

  await recorder.step("Verify registration is prevented and attendee count remains unchanged");
  await expect(page.getByRole("cell", { name: "Morgan Lee" })).toBeVisible();
  await expect(page.getByRole("cell", { name: "Jordan Kim" })).toBeVisible();
  await expect(page.getByText("Attendee registered successfully!")).toHaveCount(0);
  await expect(page.getByText("3 Total")).toHaveCount(0);

  console.log(`CODEVALID_TEST_ASSERTION_OK:${TEST_ID}`);
  await recorder.save(testInfo);
});
