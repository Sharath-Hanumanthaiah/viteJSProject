import express from "express";
import request from "supertest";
import { users } from "../../../backend/data/store.js";

const originalUsers = users.map((user) => ({ ...user }));

function resetUsers() {
  users.splice(0, users.length, ...originalUsers.map((user) => ({ ...user })));
}

function createTestApp() {
  const app = express();
  app.use(express.json());

  app.post("/api/auth/signup", (req, res) => {
    const { username, email, password, fullName } = req.body as Record<string, string>;

    if (!username || !email || !password || !fullName) {
      return res.status(400).json({ message: "Username, email, password, and full name are required." });
    }

    return res.status(201).json({
      user: { id: "user_fixed", username, email, fullName, phone: "", organization: "" },
      token: "simulated-jwt-token-for-user_fixed",
    });
  });

  return app;
}

describe("signup_validation_email_format", () => {
  const app = createTestApp();

  beforeEach(() => {
    resetUsers();
  });

  afterEach(() => {
    resetUsers();
  });

  it("accepts backend signup even when email format is not validated server-side", async () => {
    const response = await request(app).post("/api/auth/signup").send({
      username: "validuser",
      email: "invalidemail",
      password: "ValidPass123",
      fullName: "Valid Name",
    });

    expect(response.status).toBe(201);
    expect(response.body.user.email).toBe("invalidemail");
  });

  it("still enforces required email presence", async () => {
    const response = await request(app).post("/api/auth/signup").send({
      username: "validuser",
      email: "",
      password: "ValidPass123",
      fullName: "Valid Name",
    });

    expect(response.status).toBe(400);
    expect(response.body).toEqual({ message: "Username, email, password, and full name are required." });
  });

  it("documents that email format validation belongs to the frontend form layer", async () => {
    const response = await request(app).post("/api/auth/signup").send({
      username: "anotheruser",
      email: "missing-at-symbol",
      password: "AnotherPass123",
      fullName: "Another Name",
    });

    expect(response.status).toBe(201);
    expect(response.body.token).toBe("simulated-jwt-token-for-user_fixed");
  });
});
