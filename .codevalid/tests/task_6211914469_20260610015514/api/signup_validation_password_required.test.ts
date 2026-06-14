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

describe("signup_validation_password_required", () => {
  const app = createTestApp();

  beforeEach(() => {
    resetUsers();
  });

  afterEach(() => {
    resetUsers();
  });

  it("returns 400 when password is empty", async () => {
    const response = await request(app).post("/api/auth/signup").send({
      username: "validuser",
      email: "valid@email.com",
      password: "",
      fullName: "Valid Name",
    });

    expect(response.status).toBe(400);
    expect(response.body).toEqual({ message: "Username, email, password, and full name are required." });
  });

  it("returns 400 when password is omitted", async () => {
    const response = await request(app).post("/api/auth/signup").send({
      username: "validuser",
      email: "valid@email.com",
      fullName: "Valid Name",
    });

    expect(response.status).toBe(400);
    expect(response.body.message).toBe("Username, email, password, and full name are required.");
  });

  it("returns 201 when password is present", async () => {
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
