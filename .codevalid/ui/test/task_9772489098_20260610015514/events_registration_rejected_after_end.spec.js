import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../helpers/execution-recorder.js";

const TEST_ID = "events_registration_rejected_after_end";
const EVENT_ID = "event_closed_window";
const FIXED_ISO = "2024-06-25T12:00:00.000Z";

const eventRecord = {
  id: EVENT_ID,
  title: "Summer Innovation Summit",
  description: "Past event with closed registration",
  startDate: "2024-06-10",
  endDate: "2024-06-20",
  location: "Hall A",
  registrationCount: 2,
};

const initialRegistrations = [
  {
    id: "reg-existing-1",
    eventId: EVENT_ID,
    name: "Jordan Kim",
    email: "jordan@example.com",
    phone: "+1 (555) 111-2222",
    registeredAt: "2024-06-18T09:00:00.000Z",
  },
  {
    id: "reg-existing-2",
    eventId: EVENT_ID,
    name: "Morgan Lee",
    email: "morgan@example.com",
    phone: "+1 (555) 222-1111",
    registeredAt: "2024-06-19T10:00:00.000Z",
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
  const registrations = [...initialRegistrations];

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
      body: JSON.stringify(registrations),
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
        message: `Registration is closed. The event ended on ${eventRecord.endDate}.`,
      }),
    });
  });
}

test("Registration Blocked When Current Date Is After Event End", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder(TEST_ID, "Registration Blocked When Current Date Is After Event End");

  await recorder.step("Freeze browser date to 2024-06-25 and seed authenticated session");
  await freezeTime(page, FIXED_ISO);
  await seedAuthenticatedSession(page);

  await recorder.step("Register mocked event and rejection APIs for post-end registration");
  await setupScenarioMocks(page);

  await recorder.step("Navigate directly to the protected home registration route");
  await page.goto("/");

  await expect(page.getByRole("heading", { name: "Registration Desk" })).toBeVisible();
  await expect(page.getByText("Registration closed on 2024-06-20")).toBeVisible();
  await expect(page.getByText("Registration Active")).toHaveCount(0);
  await expect(page.getByText("Registration opens on", { exact: false })).toHaveCount(0);
  await expect(page.getByText("2 Total")).toBeVisible();

  await recorder.step("Attempt to register attendee after registration window has closed");
  await page.getByPlaceholder("Jane Smith").fill("Taylor Swift");
  await page.getByPlaceholder("jane@smith.com").fill("taylor@example.com");
  await page.getByPlaceholder("+1 (555) 000-0000").fill("+1 (555) 999-8888");
  await page.getByRole("button", { name: /Confirm Registration/i }).click();

  await recorder.step("Verify registration is blocked and attendee count remains unchanged");
  await expect(page.getByText("Registration is closed. The event ended on 2024-06-20.")).toBeVisible();
  await expect(page.getByText("3 Total")).toHaveCount(0);
  await expect(page.getByText("2 Total")).toBeVisible();
  await expect(page.getByRole("cell", { name: "Taylor Swift" })).toHaveCount(0);

  console.log(`CODEVALID_TEST_ASSERTION_OK:${TEST_ID}`);
  await recorder.save(testInfo);
});
