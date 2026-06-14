import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const MOCK_API_PATH = path.join(__dirname, "..", "mock-api.json");

export function loadMockApi() {
  const raw = fs.readFileSync(MOCK_API_PATH, "utf-8");
  return JSON.parse(raw);
}

function getScenario(mockApi, endpoint, scenario) {
  const endpointConfig = mockApi[endpoint];
  if (!endpointConfig) {
    throw new Error(`Mock API endpoint not found: ${endpoint}`);
  }

  const scenarioConfig = endpointConfig[scenario] ?? endpointConfig.default;
  if (!scenarioConfig) {
    throw new Error(`Mock API scenario not found: ${endpoint} -> ${scenario}`);
  }

  return scenarioConfig;
}

export async function mockSignIn(page, scenario = "success") {
  const mockApi = loadMockApi();
  const { output } = getScenario(mockApi, "POST /api/auth/signin", scenario);

  await page.route("**/api/auth/signin", async (route) => {
    if (route.request().method() !== "POST") {
      await route.continue();
      return;
    }

    await route.fulfill({
      status: output.status,
      contentType: "application/json",
      body: JSON.stringify(output.body),
    });
  });
}

export async function mockHomePageApis(page) {
  const mockApi = loadMockApi();
  const eventsScenario = getScenario(mockApi, "GET /api/events", "default");
  const registrationsScenario = getScenario(
    mockApi,
    "GET /api/registrations/event_test1",
    "default"
  );

  await page.route("**/api/events", async (route) => {
    if (route.request().method() !== "GET") {
      await route.continue();
      return;
    }

    await route.fulfill({
      status: eventsScenario.output.status,
      contentType: "application/json",
      body: JSON.stringify(eventsScenario.output.body),
    });
  });

  await page.route("**/api/registrations/**", async (route) => {
    if (route.request().method() !== "GET") {
      await route.continue();
      return;
    }

    await route.fulfill({
      status: registrationsScenario.output.status,
      contentType: "application/json",
      body: JSON.stringify(registrationsScenario.output.body),
    });
  });
}

export async function setupSignInMocks(page, { signInScenario = "success", includeHomeApis = false } = {}) {
  await mockSignIn(page, signInScenario);
  if (includeHomeApis) {
    await mockHomePageApis(page);
  }
}
