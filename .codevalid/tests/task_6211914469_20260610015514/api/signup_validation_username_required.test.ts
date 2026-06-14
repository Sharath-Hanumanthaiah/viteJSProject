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

    const existingUser = users.find(
      (u) => u.email.toLowerCase() === email.toLowerCase() || u.username.toLowerCase() === username.toLowerCase()
    );

    if (existingUser) {
      return res.status(400).json({ message: "Username or Email already registered." });
    }

    return res.status(201).json({
      user: { id: "user_fixed", username, email, fullName, phone: "", organization: "" },
      token: "simulated-jwt-token-for-user_fixed",
    });
  });

  return app;
}

describe("signup_validation_username_required", () => {
  const app = createTestApp();

  beforeEach(() => {
    resetUsers();
  });

  afterEach(() => {
    resetUsers();
  });

  it("blocks signup when username is empty", async () => {
    const response = await request(app).post("/api/auth/signup").send({
      username: "",
      email: "valid@email.com",
      password: "ValidPass123",
      fullName: "Valid Name",
    });

    expect(response.status).toBe(400);
    expect(response.body).toEqual({ message: "Username, email, password, and full name are required." });
    expect(users).toHaveLength(originalUsers.length);
  });

  it("blocks signup when username is omitted", async () => {
    const response = await request(app).post("/api/auth/signup").send({
      email: "valid@email.com",
      password: "ValidPass123",
      fullName: "Valid Name",
    });

    expect(response.status).toBe(400);
    expect(response.body.message).toBe("Username, email, password, and full name are required.");
  });

  it("still succeeds when username is provided and remaining required fields are valid", async () => {
    const response = await request(app).post("/api/auth/signup").send({
      username: "validuser",
      email: "valid@email.com",
      password: "ValidPass123",
      fullName: "Valid Name",
    });

    expect(response.status).toBe(201);
    expect(response.body.user.username).toBe("validuser");
  });
});
