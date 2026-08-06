import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";

const TEST_ID = "events_registration_edge_case_start_date";
const EVENT_ID = "event_start_boundary";
const FIXED_ISO = "2024-06-10T12:00:00.000Z";

const eventRecord = {
  id: EVENT_ID,
  title: "Summer Innovation Summit",
  description: "Boundary day opening",
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
    registeredAt: "2024-06-09T10:00:00.000Z",
  },
  {
    id: "reg-existing-1",
    eventId: EVENT_ID,
    name: "Jordan Kim",
    email: "jordan@example.com",
    phone: "+1 (555) 111-2222",
    registeredAt: "2024-06-08T09:00:00.000Z",
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
      body: JSON.stringify([{ ...eventRecord, registrationCount }]),
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
      id: "reg-start-boundary",
      eventId: payload.eventId,
      name: "Boundary Starter",
      email: "boundary.start@example.com",
      phone: "+1 (555) 300-4000",
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

test("Registration Allowed On Event Start Date", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder(TEST_ID, "Registration Allowed On Event Start Date");

  await recorder.step("Freeze browser date to the event start date and seed authenticated session");
  await freezeTime(page, FIXED_ISO);
  await seedAuthenticatedSession(page);

  await recorder.step("Register mocked APIs for start-date boundary success");
  await setupScenarioMocks(page);

  await recorder.step("Navigate to the home registration page");
  await page.goto("/");

  await expect(page.getByText("Registration Active")).toBeVisible();
  await expect(page.getByRole("button", { name: /Confirm Registration/i })).toBeEnabled();
  await expect(page.getByText("2 Total")).toBeVisible();

  await recorder.step("Submit attendee registration on the exact start date");
  await page.getByPlaceholder("Jane Smith").fill("Boundary Starter");
  await page.getByPlaceholder("jane@smith.com").fill("boundary.start@example.com");
  await page.getByPlaceholder("+1 (555) 000-0000").fill("+1 (555) 300-4000");
  await page.getByRole("button", { name: /Confirm Registration/i }).click();

  await recorder.step("Verify boundary-day registration succeeds and count increments");
  await expect(page.getByText("Attendee registered successfully!")).toBeVisible();
  await expect(page.getByText("3 Total")).toBeVisible();
  await expect(page.getByRole("cell", { name: "Boundary Starter" })).toBeVisible();

  console.log(`CODEVALID_TEST_ASSERTION_OK:${TEST_ID}`);
  await recorder.save(testInfo);
});
