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
    await import("../../../backend/server.js?case=signup_password_excluded_from_response");

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

describe("signup_password_excluded_from_response", () => {
  let app: express.Express;
  let users: Array<Record<string, any>>;
  let restore: () => void;
  let randomSpy: jest.SpiedFunction<typeof Math.random>;

  beforeEach(async () => {
    ({ app, users, restore } = await loadServer());
    users.splice(0, users.length, ...seededUsers.map((user) => ({ ...user })));
    randomSpy = jest.spyOn(Math, "random").mockReturnValue(0.333333333);
  });

  afterEach(() => {
    users.splice(0, users.length, ...seededUsers.map((user) => ({ ...user })));
    randomSpy.mockRestore();
    restore();
    jest.resetModules();
  });

  it("never returns password in the signup response", async () => {
    const response = await request(app).post("/api/auth/signup").send({
      username: "secureuser",
      email: "secure@test.com",
      password: "MySecretPassword123",
      fullName: "Security Test",
    });

    expect(response.status).toBe(201);
    expect(response.body.user).toMatchObject({
      id: expect.any(String),
      username: "secureuser",
      email: "secure@test.com",
      fullName: "Security Test",
    });
    expect("password" in response.body.user).toBe(false);
    expect(response.body.user.password).toBeUndefined();
    expect(users[2].password).toBe("MySecretPassword123");
  });
});
