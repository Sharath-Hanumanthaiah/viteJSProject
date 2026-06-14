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
    await import("../../../backend/server.js?case=signup_duplicate_email");

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

describe("signup_duplicate_email", () => {
  let app: express.Express;
  let users: Array<Record<string, any>>;
  let restore: () => void;

  beforeEach(async () => {
    ({ app, users, restore } = await loadServer());
    users.splice(0, users.length, ...seededUsers.map((user) => ({ ...user })));
    users.push({
      id: "user_existing_email",
      username: "existinguser",
      email: "existing@test.com",
      password: "password123",
      fullName: "Existing User",
      phone: "",
      organization: "",
    });
  });

  afterEach(() => {
    users.splice(0, users.length, ...seededUsers.map((user) => ({ ...user })));
    restore();
    jest.resetModules();
  });

  it("returns 400 when the email is already registered", async () => {
    const response = await request(app).post("/api/auth/signup").send({
      username: "newdifferent",
      email: "existing@test.com",
      password: "newpass123",
      fullName: "Another User",
    });

    expect(response.status).toBe(400);
    expect(response.body).toEqual({
      message: "Username or Email already registered.",
    });
    expect(users).toHaveLength(3);
  });
});
