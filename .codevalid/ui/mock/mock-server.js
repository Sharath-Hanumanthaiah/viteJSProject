// Mock server route handlers for Playwright API interception
// Registers route intercepts on a Playwright page object to simulate backend responses

import {
  mockEvents,
  mockRegistrations,
  mockSigninResponse,
  mockSignupResponse,
  mockNewRegistration,
} from "./mock-data.js";

/**
 * Set up all API route mocks on a Playwright page.
 * Call this in your test's beforeEach or at the start of a test before navigating.
 *
 * @param {import('@playwright/test').Page} page - Playwright page instance
 */
export async function setupMockRoutes(page) {
  // POST /api/auth/signin
  await page.route("**/api/auth/signin", async (route) => {
    const request = route.request();
    if (request.method() === "POST") {
      const body = JSON.parse(request.postData() || "{}");
      if (
        body.email === "test@example.com" &&
        body.password === "password123"
      ) {
        await route.fulfill({
          status: 200,
          contentType: "application/json",
          body: JSON.stringify(mockSigninResponse),
        });
      } else {
        await route.fulfill({
          status: 401,
          contentType: "application/json",
          body: JSON.stringify({ message: "Invalid email or password." }),
        });
      }
    } else {
      await route.continue();
    }
  });

  // POST /api/auth/signup
  await page.route("**/api/auth/signup", async (route) => {
    const request = route.request();
    if (request.method() === "POST") {
      await route.fulfill({
        status: 201,
        contentType: "application/json",
        body: JSON.stringify(mockSignupResponse),
      });
    } else {
      await route.continue();
    }
  });

  // GET /api/events
  await page.route("**/api/events", async (route) => {
    const request = route.request();
    if (request.method() === "GET") {
      await route.fulfill({
        status: 200,
        contentType: "application/json",
        body: JSON.stringify(mockEvents),
      });
    } else if (request.method() === "POST") {
      // Create event mock
      const body = JSON.parse(request.postData() || "{}");
      const newEvent = {
        id: "event_mock_new",
        ...body,
        registrationCount: 0,
      };
      await route.fulfill({
        status: 201,
        contentType: "application/json",
        body: JSON.stringify(newEvent),
      });
    } else {
      await route.continue();
    }
  });

  // GET /api/registrations/:eventId
  await page.route("**/api/registrations/*", async (route) => {
    const request = route.request();
    const url = request.url();

    if (request.method() === "GET") {
      // Extract eventId from URL
      const match = url.match(/\/api\/registrations\/([^/?]+)/);
      const eventId = match ? match[1] : null;
      const regs = (eventId && mockRegistrations[eventId]) || [];

      await route.fulfill({
        status: 200,
        contentType: "application/json",
        body: JSON.stringify(regs),
      });
    } else if (request.method() === "POST") {
      // POST /api/registrations
      await route.fulfill({
        status: 201,
        contentType: "application/json",
        body: JSON.stringify(mockNewRegistration),
      });
    } else {
      await route.continue();
    }
  });

  // POST /api/registrations (exact path, no trailing id)
  await page.route("**/api/registrations", async (route) => {
    const request = route.request();
    if (request.method() === "POST") {
      await route.fulfill({
        status: 201,
        contentType: "application/json",
        body: JSON.stringify(mockNewRegistration),
      });
    } else {
      await route.continue();
    }
  });
}

/**
 * Tear down all mocked routes on the given page.
 *
 * @param {import('@playwright/test').Page} page - Playwright page instance
 */
export async function teardownMockRoutes(page) {
  await page.unrouteAll({ behavior: "ignoreErrors" });
}
