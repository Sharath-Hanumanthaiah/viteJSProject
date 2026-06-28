/**
 * Mock server setup for Playwright tests.
 *
 * Usage inside a test file:
 *
 *   import { setupMockRoutes } from "../../mock/mock-server.js";
 *
 *   test.beforeEach(async ({ page }) => {
 *     await setupMockRoutes(page);
 *   });
 *
 * All API routes used by the React app are intercepted and answered with
 * the fixture data from mock-data.js so tests never need a live backend.
 */

import {
  mockUser,
  mockToken,
  mockEvents,
  mockRegistrations,
  mockNewRegistration,
} from "./mock-data.js";

/**
 * Register Playwright route intercepts on `page` for every API endpoint
 * the application calls.
 *
 * @param {import("@playwright/test").Page} page
 */
export async function setupMockRoutes(page) {
  // POST /api/auth/signin  – always succeeds with mock credentials
  await page.route("**/api/auth/signin", async (route) => {
    const body = route.request().postDataJSON();
    if (
      body?.email === mockUser.email &&
      body?.password === "password123"
    ) {
      await route.fulfill({
        status: 200,
        contentType: "application/json",
        body: JSON.stringify({ user: mockUser, token: mockToken }),
      });
    } else {
      await route.fulfill({
        status: 401,
        contentType: "application/json",
        body: JSON.stringify({ message: "Invalid email or password." }),
      });
    }
  });

  // POST /api/auth/signup  – always succeeds
  await page.route("**/api/auth/signup", async (route) => {
    await route.fulfill({
      status: 201,
      contentType: "application/json",
      body: JSON.stringify({ user: mockUser, token: mockToken }),
    });
  });

  // GET /api/events
  await page.route("**/api/events", async (route) => {
    if (route.request().method() === "GET") {
      await route.fulfill({
        status: 200,
        contentType: "application/json",
        body: JSON.stringify(mockEvents),
      });
    } else {
      // POST /api/events – echo back the first mock event
      await route.fulfill({
        status: 201,
        contentType: "application/json",
        body: JSON.stringify({ ...mockEvents[0], registrationCount: 0 }),
      });
    }
  });

  // GET /api/registrations/:eventId
  await page.route("**/api/registrations/**", async (route) => {
    if (route.request().method() === "GET") {
      const url = route.request().url();
      const eventId = url.split("/api/registrations/")[1]?.split("?")[0];
      const regs = mockRegistrations[eventId] ?? [];
      await route.fulfill({
        status: 200,
        contentType: "application/json",
        body: JSON.stringify(regs),
      });
    } else {
      // POST /api/registrations
      await route.fulfill({
        status: 201,
        contentType: "application/json",
        body: JSON.stringify(mockNewRegistration),
      });
    }
  });
}

/**
 * Inject a valid user session into the browser's localStorage so that
 * ProtectedRoute lets the test navigate directly to authenticated pages.
 *
 * @param {import("@playwright/test").Page} page
 */
export async function injectUserSession(page) {
  await page.evaluate(
    ([user, token]) => {
      localStorage.setItem("user", JSON.stringify(user));
      localStorage.setItem("token", token);
    },
    [mockUser, mockToken]
  );
}
