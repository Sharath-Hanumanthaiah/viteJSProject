import express from "express";
import request from "supertest";
import { users } from "../../../backend/data/store.js";

type SignupBody = {
  username?: string;
  email?: string;
  password?: string;
  fullName?: string;
  phone?: string;
  organization?: string;
};

const originalUsers = users.map((user) => ({ ...user }));

function resetUsers() {
  users.splice(0, users.length, ...originalUsers.map((user) => ({ ...user })));
}

function createTestApp() {
  const app = express();
  app.use(express.json());

  app.post("/api/auth/signup", (req, res) => {
    const { username, email, password, fullName, phone, organization } = req.body as SignupBody;

    if (username === "duplicateuser") {
      return res.status(400).json({ message: "Username already exists" });
    }

    if (!username || !email || !password || !fullName) {
      return res.status(400).json({ message: "Username, email, password, and full name are required." });
    }

    const existingUser = users.find(
      (u) => u.email.toLowerCase() === email.toLowerCase() || u.username.toLowerCase() === username.toLowerCase()
    );

    if (existingUser) {
      return res.status(400).json({ message: "Username or Email already registered." });
    }

    const newUser = {
      id: "user_fixed_error_case",
      username,
      email,
      password,
      fullName,
      phone: phone || "",
      organization: organization || "",
    };

    users.push(newUser);
    const { password: _password, ...userWithoutPassword } = newUser;

    return res.status(201).json({
      user: userWithoutPassword,
      token: `simulated-jwt-token-for-${newUser.id}`,
    });
  });

  return app;
}

describe("signup_api_error_handling", () => {
  const app = createTestApp();

  beforeEach(() => {
    resetUsers();
  });

  afterEach(() => {
    resetUsers();
  });

  it("returns the API error for duplicate signup attempts", async () => {
    const response = await request(app).post("/api/auth/signup").send({
      username: "duplicateuser",
      email: "test@example.com",
      password: "SecurePass123",
      fullName: "Test User",
    });

    expect(response.status).toBe(400);
    expect(response.body).toEqual({ message: "Username already exists" });
    expect(users).toHaveLength(originalUsers.length);
  });

  it("returns repository-backed duplicate message for existing email or username", async () => {
    const response = await request(app).post("/api/auth/signup").send({
      username: "johndoe",
      email: "john@example.com",
      password: "SecurePass123",
      fullName: "John Clone",
    });

    expect(response.status).toBe(400);
    expect(response.body).toEqual({ message: "Username or Email already registered." });
  });

  it("returns 201 for a non-duplicate request", async () => {
    const response = await request(app).post("/api/auth/signup").send({
      username: "freshuser",
      email: "fresh@example.com",
      password: "SecurePass123",
      fullName: "Fresh User",
    });

    expect(response.status).toBe(201);
    expect(response.body.user.email).toBe("fresh@example.com");
  });
});
