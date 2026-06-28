import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../helpers/execution-recorder.js";

const TEST_ID = "events_registration_happy_path_within_range";
const EVENT_ID = "event_range_open";
const FIXED_ISO = "2024-06-15T12:00:00.000Z";

const eventRecord = {
  id: EVENT_ID,
  title: "Summer Innovation Summit",
  description: "Annual registration-ready event",
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
  let registrationCount = eventRecord.registrationCount;
  const registrations = [...initialRegistrations];

  await page.route("**/api/events", async (route) => {
    if (route.request().method() !== "GET") {
      await route.continue();
      return;
    }

    await route.fulfill({
      status: 200,
      contentType: "application/json",
      body: JSON.stringify([
        {
          ...eventRecord,
          registrationCount,
        },
      ]),
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

    const payload = route.request().postDataJSON();
    const created = {
      id: "reg-new-success",
      eventId: payload.eventId,
      name: "Taylor Swift",
      email: "taylor@example.com",
      phone: "+1 (555) 999-8888",
      registeredAt: FIXED_ISO,
    };

    registrations.unshift(created);
    registrationCount += 1;

    await route.fulfill({
      status: 201,
      contentType: "application/json",
      body: JSON.stringify(created),
    });
  });
}

test("Successful Registration When Current Date Is Within Event Range", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder(TEST_ID, "Successful Registration When Current Date Is Within Event Range");

  await recorder.step("Freeze browser date to 2024-06-15 and seed authenticated session");
  await freezeTime(page, FIXED_ISO);
  await seedAuthenticatedSession(page);

  await recorder.step("Register mocked event, registrations list, and successful registration APIs");
  await setupScenarioMocks(page);

  await recorder.step("Navigate to the protected home registration page");
  await page.goto("/");

  await expect(page.getByRole("heading", { name: "Registration Desk" })).toBeVisible();
  await expect(page.getByText("Registration Active")).toBeVisible();
  await expect(page.getByText("Registration opens on", { exact: false })).toHaveCount(0);
  await expect(page.getByText("Registration closed on", { exact: false })).toHaveCount(0);
  await expect(page.getByText("2024-06-10")).toBeVisible();
  await expect(page.getByText("2024-06-20")).toBeVisible();
  await expect(page.getByRole("combobox")).toHaveValue(EVENT_ID);
  await expect(page.getByText("2 Total")).toBeVisible();

  await recorder.step("Fill attendee details and submit registration");
  await page.getByPlaceholder("Jane Smith").fill("Taylor Swift");
  await page.getByPlaceholder("jane@smith.com").fill("taylor@example.com");
  await page.getByPlaceholder("+1 (555) 000-0000").fill("+1 (555) 999-8888");
  await page.getByRole("button", { name: /Confirm Registration/i }).click();

  await recorder.step("Verify success confirmation and attendee count increment");
  await expect(page.getByText("Attendee registered successfully!")).toBeVisible();
  await expect(page.getByText("3 Total")).toBeVisible();
  await expect(page.getByRole("cell", { name: "Taylor Swift" })).toBeVisible();
  await expect(page.getByText("taylor@example.com")).toBeVisible();
  await expect(page.getByText("+1 (555) 999-8888")).toBeVisible();

  console.log(`CODEVALID_TEST_ASSERTION_OK:${TEST_ID}`);
  await recorder.save(testInfo);
});
