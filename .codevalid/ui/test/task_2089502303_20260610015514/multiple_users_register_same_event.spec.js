import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { setupAuthenticatedSession } from "../../helpers/mock-api.js";
import { validUpcomingEvent, registrationUserA, registrationUserB } from "../../mock/mock-data.js";

function json(route, status, body) {
  return route.fulfill({
    status,
    contentType: "application/json",
    body: JSON.stringify(body),
  });
}

test("Multiple users can register for the same event with unique emails", async ({ browser }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "multiple_users_register_same_event",
    testTitle: "Multiple users can register for the same event with unique emails",
  });

  const registrations = [registrationUserA];

  try {
    const contextA = await browser.newContext({ baseURL: testInfo.project.use.baseURL });
    const pageA = await contextA.newPage();
    const contextB = await browser.newContext({ baseURL: testInfo.project.use.baseURL });
    const pageB = await contextB.newPage();

    await recorder.step("Register route mocks for both browser contexts", async () => {
      for (const page of [pageA, pageB]) {
        await setupAuthenticatedSession(page);
        await page.route("**/api/events", async (route) =>
          json(route, 200, [{ ...validUpcomingEvent, registrationCount: registrations.length }])
        );
        await page.route("**/api/registrations/*", async (route) => json(route, 200, [...registrations]));
        await page.route("**/api/registrations", async (route) => {
          const body = route.request().postDataJSON();
          const next = body.email === "b@example.com" ? registrationUserB : registrationUserA;
          if (!registrations.find((item) => item.email === next.email)) {
            registrations.unshift(next);
          }
          return json(route, 201, next);
        });
      }
    });

    await recorder.step("User A sees existing registration and User B submits a new one", async () => {
      await pageA.goto("/");
      await expect(pageA.getByText("1 Total")).toBeVisible();
      await expect(pageA.getByText("a@example.com")).toBeVisible();

      await pageB.goto("/");
      await pageB.locator('[name="name"]').fill("User B");
      await pageB.locator('[name="email"]').fill("b@example.com");
      await pageB.locator('[name="phone"]').fill("+1 (555) 202-0002");
      await pageB.getByRole("button", { name: /Confirm Registration/ }).click();
      await expect(pageB.getByText("2 Total")).toBeVisible();
      await expect(pageB.getByText("b@example.com")).toBeVisible();
    });

    await recorder.step("Refresh the original view and verify total becomes two", async () => {
      await pageA.reload();
      await expect(pageA.getByText("2 Total")).toBeVisible();
      await expect(pageA.getByText("a@example.com")).toBeVisible();
      await expect(pageA.getByText("b@example.com")).toBeVisible();
      await contextA.close();
      await contextB.close();
    });

    console.log("CODEVALID_TEST_ASSERTION_OK:multiple_users_register_same_event");
  } finally {
    await recorder.save(testInfo);
  }
});
