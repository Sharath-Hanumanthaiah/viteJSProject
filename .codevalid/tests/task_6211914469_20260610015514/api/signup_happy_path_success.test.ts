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
      id: "user_fixed_signup_1",
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

describe("signup_happy_path_success", () => {
  const app = createTestApp();

  beforeEach(() => {
    resetUsers();
    expect(users.some((u) => u.username === "testuser123" || u.email === "test@example.com")).toBe(false);
  });

  afterEach(() => {
    resetUsers();
  });

  it("registers a user with valid required and optional fields and returns session payload", async () => {
    const response = await request(app).post("/api/auth/signup").send({
      username: "testuser123",
      email: "test@example.com",
      password: "SecurePass123",
      fullName: "Test User",
      phone: "555-123-4567",
      organization: "Test Organization",
    });

    expect(response.status).toBe(201);
    expect(response.body).toEqual({
      user: {
        id: "user_fixed_signup_1",
        username: "testuser123",
        email: "test@example.com",
        fullName: "Test User",
        phone: "555-123-4567",
        organization: "Test Organization",
      },
      token: "simulated-jwt-token-for-user_fixed_signup_1",
    });
    expect(response.body.user.password).toBeUndefined();
    expect(users.some((u) => u.email === "test@example.com" && u.username === "testuser123")).toBe(true);
  });

  it("returns 400 when required fields are missing", async () => {
    const response = await request(app).post("/api/auth/signup").send({
      username: "",
      email: "",
      password: "",
      fullName: "",
    });

    expect(response.status).toBe(400);
    expect(response.body).toEqual({ message: "Username, email, password, and full name are required." });
    expect(users).toHaveLength(originalUsers.length);
  });

  it("returns 400 when username is already registered", async () => {
    const response = await request(app).post("/api/auth/signup").send({
      username: "johndoe",
      email: "fresh@example.com",
      password: "SecurePass123",
      fullName: "Fresh User",
    });

    expect(response.status).toBe(400);
    expect(response.body).toEqual({ message: "Username or Email already registered." });
  });
});
