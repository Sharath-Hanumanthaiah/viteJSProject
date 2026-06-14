import request from "supertest";
import express from "express";

type TestContext = {
  app: express.Express;
  users: Array<Record<string, any>>;
  restore: () => void;
};

const seededUsers = [
  {
    id: "user_1",
    username: "johndoe",
    email: "john@example.com",
    password: "password123",
    fullName: "John Doe",
    phone: "+1 (555) 019-2834",
    organization: "Acme Tech Solutions",
  },
  {
    id: "user_2",
    username: "janemiller",
    email: "jane@example.com",
    password: "password123",
    fullName: "Jane Miller",
    phone: "+1 (555) 014-9876",
    organization: "Innovate Labs",
  },
];

async function loadServer(): Promise<TestContext> {
  let capturedApp: express.Express | undefined;
  const originalListen = express.application.listen;

  express.application.listen = function mockedListen(this: express.Express, ..._args: any[]) {
    capturedApp = this;
    return { close: () => undefined } as any;
  } as any;

  try {
    const store = await import("../../../backend/data/store.js");
    await import("../../../backend/server.js?case=signup_missing_password");

    if (!capturedApp) {
      throw new Error("Failed to capture Express app from backend/server.js");
    }

    return {
      app: capturedApp,
      users: store.users as Array<Record<string, any>>,
      restore: () => {
        express.application.listen = originalListen;
      },
    };
  } catch (error) {
    express.application.listen = originalListen;
    throw error;
  }
}

describe("signup_missing_password", () => {
  let app: express.Express;
  let users: Array<Record<string, any>>;
  let restore: () => void;

  beforeEach(async () => {
    ({ app, users, restore } = await loadServer());
    users.splice(0, users.length, ...seededUsers.map((user) => ({ ...user })));
  });

  afterEach(() => {
    users.splice(0, users.length, ...seededUsers.map((user) => ({ ...user })));
    restore();
    jest.resetModules();
  });

  it("returns 400 when password is missing", async () => {
    const response = await request(app).post("/api/auth/signup").send({
      username: "nopassuser",
      email: "nopass@test.com",
      fullName: "Test User",
    });

    expect(response.status).toBe(400);
    expect(response.body).toEqual({
      message: "Username, email, password, and full name are required.",
    });
    expect(users).toHaveLength(2);
  });
});
