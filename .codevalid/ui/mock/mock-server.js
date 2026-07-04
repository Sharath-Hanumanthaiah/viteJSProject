/**
 * mock-server.js
 * --------------
 * Lightweight Playwright route-interception helper.
 *
 * Usage inside a test file:
 *
 *   import { setupMockServer } from "../mock/mock-server.js";
 *
 *   test.beforeEach(async ({ page }) => {
 *     await setupMockServer(page);
 *   });
 *
 * All /api/* routes are intercepted by default so tests run with zero
 * dependency on a live Express backend.  Individual routes can be
 * overridden per-test with page.route() after calling setupMockServer().
 */

import { mockUsers, mockEvents, mockRegistrations, mockResponses } from "./mock-data.js";

/**
 * Attach Playwright route interceptors to `page` that mimic every
 * endpoint exposed by backend/server.js.
 *
 * @param {import("@playwright/test").Page} page
 */
export async function setupMockServer(page) {
  // ── POST /api/auth/signup ───────────────────────────────────────────────
  await page.route("**/api/auth/signup", async (route) => {
    const body = route.request().postDataJSON();
    const { username, email, password, fullName } = body ?? {};

    if (!username || !email || !password || !fullName) {
      return route.fulfill({
        status: 400,
        contentType: "application/json",
        body: JSON.stringify(
          mockResponses.validationError(
            "Username, email, password, and full name are required."
          )
        ),
      });
    }

    const existing = mockUsers.find(
      (u) =>
        u.email.toLowerCase() === email.toLowerCase() ||
        u.username.toLowerCase() === username.toLowerCase()
    );

    if (existing) {
      return route.fulfill({
        status: 400,
        contentType: "application/json",
        body: JSON.stringify(mockResponses.signupDuplicate),
      });
    }

    const newUser = {
      id: `user_${Math.random().toString(36).substr(2, 8)}`,
      username,
      email,
      password,
      fullName,
      phone: body.phone ?? "",
      organization: body.organization ?? "",
    };
    // persist for the lifetime of this page so signin works afterwards
    mockUsers.push(newUser);

    return route.fulfill({
      status: 201,
      contentType: "application/json",
      body: JSON.stringify(mockResponses.signupSuccess(newUser)),
    });
  });

  // ── POST /api/auth/signin ───────────────────────────────────────────────
  await page.route("**/api/auth/signin", async (route) => {
    const { email, password } = route.request().postDataJSON() ?? {};

    if (!email || !password) {
      return route.fulfill({
        status: 400,
        contentType: "application/json",
        body: JSON.stringify(
          mockResponses.validationError("Email and password are required.")
        ),
      });
    }

    const user = mockUsers.find(
      (u) => u.email.toLowerCase() === email.toLowerCase()
    );

    if (!user || user.password !== password) {
      return route.fulfill({
        status: 401,
        contentType: "application/json",
        body: JSON.stringify(mockResponses.signinFailure),
      });
    }

    return route.fulfill({
      status: 200,
      contentType: "application/json",
      body: JSON.stringify(mockResponses.signinSuccess(user)),
    });
  });

  // ── GET /api/events ─────────────────────────────────────────────────────
  await page.route("**/api/events", async (route) => {
    if (route.request().method() === "GET") {
      return route.fulfill({
        status: 200,
        contentType: "application/json",
        body: JSON.stringify(mockResponses.eventsList),
      });
    }

    // POST /api/events – create a new event
    const body = route.request().postDataJSON() ?? {};
    const { title, startDate, endDate, location } = body;

    if (!title || !startDate || !endDate || !location) {
      return route.fulfill({
        status: 400,
        contentType: "application/json",
        body: JSON.stringify(
          mockResponses.validationError(
            "Title, start date, end date, and location are required."
          )
        ),
      });
    }

    if (new Date(startDate) > new Date(endDate)) {
      return route.fulfill({
        status: 400,
        contentType: "application/json",
        body: JSON.stringify(
          mockResponses.validationError(
            "Start date must be before or equal to the end date."
          )
        ),
      });
    }

    const newEvent = {
      id: `event_${Math.random().toString(36).substr(2, 6)}`,
      title,
      description: body.description ?? "",
      startDate,
      endDate,
      location,
    };
    mockEvents.push({ ...newEvent, registrationCount: 0 });

    return route.fulfill({
      status: 201,
      contentType: "application/json",
      body: JSON.stringify(mockResponses.eventCreated(newEvent)),
    });
  });

  // ── GET /api/registrations/:eventId ────────────────────────────────────
  await page.route("**/api/registrations/*", async (route) => {
    if (route.request().method() === "GET") {
      const url = new URL(route.request().url());
      const eventId = url.pathname.split("/").pop();

      const event = mockEvents.find((e) => e.id === eventId);
      if (!event) {
        return route.fulfill({
          status: 404,
          contentType: "application/json",
          body: JSON.stringify(mockResponses.notFound),
        });
      }

      return route.fulfill({
        status: 200,
        contentType: "application/json",
        body: JSON.stringify(mockResponses.registrationsList(eventId)),
      });
    }

    // POST /api/registrations – register for event
    const body = route.request().postDataJSON() ?? {};
    const { eventId, name, email, phone } = body;

    if (!eventId || !name || !email || !phone) {
      return route.fulfill({
        status: 400,
        contentType: "application/json",
        body: JSON.stringify(
          mockResponses.validationError(
            "Event, name, email, and phone number are required."
          )
        ),
      });
    }

    const event = mockEvents.find((e) => e.id === eventId);
    if (!event) {
      return route.fulfill({
        status: 404,
        contentType: "application/json",
        body: JSON.stringify(mockResponses.notFound),
      });
    }

    const alreadyRegistered = mockRegistrations.some(
      (r) =>
        r.eventId === eventId &&
        r.email.toLowerCase() === email.toLowerCase()
    );

    if (alreadyRegistered) {
      return route.fulfill({
        status: 400,
        contentType: "application/json",
        body: JSON.stringify(mockResponses.registrationDuplicate),
      });
    }

    const newReg = mockResponses.registrationCreated(body);
    mockRegistrations.push(newReg);

    return route.fulfill({
      status: 201,
      contentType: "application/json",
      body: JSON.stringify(newReg),
    });
  });
}

/**
 * Convenience helper – intercept signin to always succeed with a
 * pre-defined test user.  Call this from tests that need an
 * already-authenticated page without caring about credentials.
 *
 * @param {import("@playwright/test").Page} page
 * @param {object} [userOverride]
 */
export async function mockSigninSuccess(page, userOverride = {}) {
  const user = {
    id: "user_test001",
    username: "testuser",
    email: "test@example.com",
    fullName: "Test User",
    phone: "555-0100",
    organization: "CodeValid QA",
    ...userOverride,
  };

  await page.route("**/api/auth/signin", async (route) => {
    await route.fulfill({
      status: 200,
      contentType: "application/json",
      body: JSON.stringify({
        user,
        token: `simulated-jwt-token-for-${user.id}`,
      }),
    });
  });
}

/**
 * Simulate a pre-authenticated session by injecting localStorage tokens
 * directly – no network round-trip required.
 *
 * @param {import("@playwright/test").Page} page
 * @param {object} [userOverride]
 */
export async function injectAuthSession(page, userOverride = {}) {
  const user = {
    id: "user_test001",
    username: "testuser",
    email: "test@example.com",
    fullName: "Test User",
    ...userOverride,
  };

  await page.addInitScript(
    ({ u, token }) => {
      window.localStorage.setItem("user", JSON.stringify(u));
      window.localStorage.setItem("token", token);
    },
    { u: user, token: `simulated-jwt-token-for-${user.id}` }
  );
}
