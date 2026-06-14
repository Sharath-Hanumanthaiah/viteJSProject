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

describe("signup_clear_field_error_on_change", () => {
  const app = createTestApp();

  beforeEach(() => {
    resetUsers();
  });

  afterEach(() => {
    resetUsers();
  });

  it("produces the backend validation error before a corrected retry", async () => {
    const invalidResponse = await request(app).post("/api/auth/signup").send({
      username: "",
      email: "valid@email.com",
      password: "ValidPass123",
      fullName: "Valid Name",
    });

    expect(invalidResponse.status).toBe(400);
    expect(invalidResponse.body.message).toBe("Username, email, password, and full name are required.");

    const validResponse = await request(app).post("/api/auth/signup").send({
      username: "n",
      email: "valid@email.com",
      password: "ValidPass123",
      fullName: "Valid Name",
    });

    expect(validResponse.status).toBe(201);
    expect(validResponse.body.user.username).toBe("n");
  });

  it("keeps store unchanged after failed submission", async () => {
    await request(app).post("/api/auth/signup").send({
      username: "",
      email: "valid@email.com",
      password: "ValidPass123",
      fullName: "Valid Name",
    });

    expect(users).toHaveLength(originalUsers.length);
  });

  it("allows success once the missing field is supplied", async () => {
    const response = await request(app).post("/api/auth/signup").send({
      username: "typeduser",
      email: "typed@example.com",
      password: "ValidPass123",
      fullName: "Typed Name",
    });

    expect(response.status).toBe(201);
    expect(response.body.user.email).toBe("typed@example.com");
  });
});
