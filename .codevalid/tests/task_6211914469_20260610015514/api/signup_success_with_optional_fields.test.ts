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
    await import("../../../backend/server.js?case=signup_success_with_optional_fields");

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

describe("signup_success_with_optional_fields", () => {
  let app: express.Express;
  let users: Array<Record<string, any>>;
  let restore: () => void;
  let randomSpy: jest.SpiedFunction<typeof Math.random>;

  beforeEach(async () => {
    ({ app, users, restore } = await loadServer());
    users.splice(0, users.length, ...seededUsers.map((user) => ({ ...user })));
    randomSpy = jest.spyOn(Math, "random").mockReturnValue(0.222222222);
  });

  afterEach(() => {
    users.splice(0, users.length, ...seededUsers.map((user) => ({ ...user })));
    randomSpy.mockRestore();
    restore();
    jest.resetModules();
  });

  it("stores and returns optional phone and organization fields", async () => {
    const response = await request(app).post("/api/auth/signup").send({
      username: "acmeuser",
      email: "employee@acme.com",
      password: "Password456",
      fullName: "Acme Employee",
      phone: "+1-555-123-4567",
      organization: "Acme Corp",
    });

    expect(response.status).toBe(201);
    expect(response.body.user).toEqual({
      id: expect.stringMatching(/^user_/),
      username: "acmeuser",
      email: "employee@acme.com",
      fullName: "Acme Employee",
      phone: "+1-555-123-4567",
      organization: "Acme Corp",
    });
    expect(response.body.token).toBe(`simulated-jwt-token-for-${response.body.user.id}`);
    expect(users[2]).toMatchObject({
      username: "acmeuser",
      email: "employee@acme.com",
      password: "Password456",
      fullName: "Acme Employee",
      phone: "+1-555-123-4567",
      organization: "Acme Corp",
    });
  });

  it("defaults optional fields to empty strings when omitted", async () => {
    const response = await request(app).post("/api/auth/signup").send({
      username: "plainuser",
      email: "plain@example.com",
      password: "Password456",
      fullName: "Plain User",
    });

    expect(response.status).toBe(201);
    expect(response.body.user.phone).toBe("");
    expect(response.body.user.organization).toBe("");
  });
});
