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
    await import("../../../backend/server.js?case=signup_success_all_required_fields");

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

describe("signup_success_all_required_fields", () => {
  let app: express.Express;
  let users: Array<Record<string, any>>;
  let restore: () => void;
  let randomSpy: jest.SpiedFunction<typeof Math.random>;

  beforeEach(async () => {
    ({ app, users, restore } = await loadServer());
    users.splice(0, users.length, ...seededUsers.map((user) => ({ ...user })));
    randomSpy = jest.spyOn(Math, "random").mockReturnValue(0.123456789);
  });

  afterEach(() => {
    users.splice(0, users.length, ...seededUsers.map((user) => ({ ...user })));
    randomSpy.mockRestore();
    restore();
    jest.resetModules();
  });

  it("creates a user when all required signup fields are provided", async () => {
    const response = await request(app).post("/api/auth/signup").send({
      username: "newuser123",
      email: "newuser@example.com",
      password: "SecurePass123!",
      fullName: "New User",
    });

    expect(response.status).toBe(201);
    expect(response.body.user).toEqual({
      id: expect.stringMatching(/^user_/),
      username: "newuser123",
      email: "newuser@example.com",
      fullName: "New User",
      phone: "",
      organization: "",
    });
    expect(response.body.user.password).toBeUndefined();
    expect(response.body.token).toBe(`simulated-jwt-token-for-${response.body.user.id}`);
    expect(users).toHaveLength(3);
    expect(users[2]).toMatchObject({
      username: "newuser123",
      email: "newuser@example.com",
      password: "SecurePass123!",
      fullName: "New User",
      phone: "",
      organization: "",
    });
  });

  it("returns 400 when a required field is omitted", async () => {
    const response = await request(app).post("/api/auth/signup").send({
      username: "missingemail",
      password: "SecurePass123!",
      fullName: "Missing Email",
    });

    expect(response.status).toBe(400);
    expect(response.body).toEqual({
      message: "Username, email, password, and full name are required.",
    });
    expect(users).toHaveLength(2);
  });
});
