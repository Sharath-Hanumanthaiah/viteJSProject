/**
 * Mock server setup for CodeValid UI Playwright tests.
 *
 * Usage in a test file:
 *   import { setupMockServer } from "../mock/mock-server.js";
 *
 *   test.beforeEach(async ({ page }) => {
 *     await setupMockServer(page);
 *   });
 *
 * The mock intercepts all /api/* routes and returns the pre-seeded mock data,
 * eliminating the need for a running backend during Playwright runs.
 */

import {
  mockUsers,
  mockEvents,
  mockRegistrations,
  mockAuthResponses,
} from "./mock-data.js";

/**
 * Register Playwright route handlers on the given page to intercept API calls.
 * @param {import("@playwright/test").Page} page
 */
export async function setupMockServer(page) {
  // ── Auth: Sign-in ─────────────────────────────────────────────────────────
  await page.route("**/api/auth/signin", async (route) => {
    const body = JSON.parse(route.request().postData() || "{}");
    const user = mockUsers.find(
      (u) =>
        u.email.toLowerCase() === (body.email || "").toLowerCase() &&
        u.password === body.password
    );

    if (user) {
      await route.fulfill({
        status: 200,
        contentType: "application/json",
        body: JSON.stringify(mockAuthResponses.signinSuccess),
      });
    } else {
      await route.fulfill({
        status: 401,
        contentType: "application/json",
        body: JSON.stringify(mockAuthResponses.signinFailure),
      });
    }
  });

  // ── Auth: Sign-up ─────────────────────────────────────────────────────────
  await page.route("**/api/auth/signup", async (route) => {
    const body = JSON.parse(route.request().postData() || "{}");
    const exists = mockUsers.some(
      (u) =>
        u.email.toLowerCase() === (body.email || "").toLowerCase() ||
        u.username.toLowerCase() === (body.username || "").toLowerCase()
    );

    if (exists) {
      await route.fulfill({
        status: 400,
        contentType: "application/json",
        body: JSON.stringify({ message: "Username or Email already registered." }),
      });
      return;
    }

    const newUser = {
      id: `user_${Math.random().toString(36).substr(2, 9)}`,
      username: body.username,
      email: body.email,
      password: body.password,
      fullName: body.fullName,
      phone: body.phone || "",
      organization: body.organization || "",
    };
    mockUsers.push(newUser);

    await route.fulfill({
      status: 201,
      contentType: "application/json",
      body: JSON.stringify(mockAuthResponses.signupSuccess(newUser)),
    });
  });

  // ── Events: List ──────────────────────────────────────────────────────────
  await page.route("**/api/events", async (route) => {
    if (route.request().method() === "GET") {
      await route.fulfill({
        status: 200,
        contentType: "application/json",
        body: JSON.stringify(mockEvents),
      });
    } else if (route.request().method() === "POST") {
      // Create event
      const body = JSON.parse(route.request().postData() || "{}");
      const newEvent = {
        id: `event_${Math.random().toString(36).substr(2, 9)}`,
        title: body.title,
        description: body.description || "",
        startDate: body.startDate,
        endDate: body.endDate,
        location: body.location,
        registrationCount: 0,
      };
      mockEvents.push(newEvent);
      await route.fulfill({
        status: 201,
        contentType: "application/json",
        body: JSON.stringify(newEvent),
      });
    } else {
      await route.continue();
    }
  });

  // ── Registrations: List by event ──────────────────────────────────────────
  await page.route("**/api/registrations/*", async (route) => {
    const url = route.request().url();
    const eventId = url.split("/api/registrations/")[1]?.split("?")[0];

    if (route.request().method() === "GET") {
      const eventRegs = mockRegistrations.filter((r) => r.eventId === eventId);
      await route.fulfill({
        status: 200,
        contentType: "application/json",
        body: JSON.stringify(eventRegs),
      });
    } else {
      await route.continue();
    }
  });

  // ── Registrations: Create ─────────────────────────────────────────────────
  await page.route("**/api/registrations", async (route) => {
    if (route.request().method() !== "POST") {
      await route.continue();
      return;
    }

    const body = JSON.parse(route.request().postData() || "{}");
    const event = mockEvents.find((e) => e.id === body.eventId);

    if (!event) {
      await route.fulfill({
        status: 404,
        contentType: "application/json",
        body: JSON.stringify({ message: "Event not found." }),
      });
      return;
    }

    const duplicate = mockRegistrations.some(
      (r) =>
        r.eventId === body.eventId &&
        r.email.toLowerCase() === (body.email || "").toLowerCase()
    );

    if (duplicate) {
      await route.fulfill({
        status: 400,
        contentType: "application/json",
        body: JSON.stringify({
          message: "This email is already registered for this event.",
        }),
      });
      return;
    }

    const newReg = {
      id: `reg_${Math.random().toString(36).substr(2, 9)}`,
      eventId: body.eventId,
      name: body.name,
      email: body.email,
      phone: body.phone,
      registeredAt: new Date().toISOString(),
    };
    mockRegistrations.push(newReg);
    event.registrationCount = (event.registrationCount || 0) + 1;

    await route.fulfill({
      status: 201,
      contentType: "application/json",
      body: JSON.stringify(newReg),
    });
  });
}
