/**
 * mock-server.js
 *
 * Playwright route-interception helpers that intercept all /api/* calls and
 * return the mock data defined in mock-data.js.
 *
 * Usage inside a test:
 *   import { setupApiMocks, teardownApiMocks } from "../../mocks/mock-server.js";
 *
 *   test.beforeEach(async ({ page }) => {
 *     await setupApiMocks(page);
 *   });
 *
 *   test.afterEach(async ({ page }) => {
 *     await teardownApiMocks(page);
 *   });
 */

import {
  mockEvents,
  mockRegistrations,
  mockResponses,
} from "./mock-data.js";

/**
 * Register Playwright route interceptions for all API endpoints used by
 * the Event-Registration SPA.
 *
 * @param {import('@playwright/test').Page} page
 */
export async function setupApiMocks(page) {
  // ── POST /api/auth/signin ──────────────────────────────────────────────────
  await page.route("**/api/auth/signin", async (route) => {
    const body = route.request().postDataJSON();
    const { email, password } = body ?? {};

    if (email === "john@example.com" && password === "password123") {
      await route.fulfill({
        status: 200,
        contentType: "application/json",
        body: JSON.stringify(mockResponses.signIn.success),
      });
    } else {
      await route.fulfill({
        status: 401,
        contentType: "application/json",
        body: JSON.stringify(mockResponses.signIn.failure),
      });
    }
  });

  // ── POST /api/auth/signup ──────────────────────────────────────────────────
  await page.route("**/api/auth/signup", async (route) => {
    await route.fulfill({
      status: 201,
      contentType: "application/json",
      body: JSON.stringify(mockResponses.signUp.success),
    });
  });

  // ── GET /api/events ────────────────────────────────────────────────────────
  await page.route("**/api/events", async (route) => {
    if (route.request().method() === "GET") {
      await route.fulfill({
        status: 200,
        contentType: "application/json",
        body: JSON.stringify(mockEvents),
      });
    } else {
      // POST /api/events – create event
      const body = route.request().postDataJSON() ?? {};
      const newEvent = {
        id: "event_new",
        title: body.title ?? "New Event",
        description: body.description ?? "",
        startDate: body.startDate ?? new Date().toISOString().split("T")[0],
        endDate: body.endDate ?? new Date().toISOString().split("T")[0],
        location: body.location ?? "TBD",
        registrationCount: 0,
      };
      await route.fulfill({
        status: 201,
        contentType: "application/json",
        body: JSON.stringify(newEvent),
      });
    }
  });

  // ── GET /api/registrations/:eventId ───────────────────────────────────────
  await page.route("**/api/registrations/*", async (route) => {
    const url = route.request().url();
    const eventId = url.split("/api/registrations/")[1]?.split("?")[0];
    const regs = mockRegistrations[eventId] ?? [];
    await route.fulfill({
      status: 200,
      contentType: "application/json",
      body: JSON.stringify(regs),
    });
  });

  // ── POST /api/registrations ────────────────────────────────────────────────
  await page.route("**/api/registrations", async (route) => {
    const body = route.request().postDataJSON() ?? {};

    // Simulate duplicate-email check against in-memory mocks
    const existingRegs = mockRegistrations[body.eventId] ?? [];
    const isDuplicate = existingRegs.some(
      (r) => r.email?.toLowerCase() === body.email?.toLowerCase()
    );

    if (isDuplicate) {
      await route.fulfill({
        status: 400,
        contentType: "application/json",
        body: JSON.stringify(mockResponses.registration.duplicate),
      });
      return;
    }

    const newReg = {
      id: `reg_${Date.now()}`,
      eventId: body.eventId,
      name: body.name,
      email: body.email,
      phone: body.phone,
      registeredAt: new Date().toISOString(),
    };
    await route.fulfill({
      status: 201,
      contentType: "application/json",
      body: JSON.stringify(newReg),
    });
  });
}

/**
 * Remove all previously registered route handlers.
 *
 * @param {import('@playwright/test').Page} page
 */
export async function teardownApiMocks(page) {
  await page.unrouteAll({ behavior: "ignoreErrors" });
}
