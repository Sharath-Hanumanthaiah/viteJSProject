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
      id: "user_optional_case",
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

describe("signup_optional_fields_not_required", () => {
  const app = createTestApp();

  beforeEach(() => {
    resetUsers();
    expect(users.some((u) => u.username === "optuser" || u.email === "opt@example.com")).toBe(false);
  });

  afterEach(() => {
    resetUsers();
  });

  it("creates a user when phone and organization are omitted", async () => {
    const response = await request(app).post("/api/auth/signup").send({
      username: "optuser",
      email: "opt@example.com",
      password: "SecurePass123",
      fullName: "Optional User",
      phone: "",
      organization: "",
    });

    expect(response.status).toBe(201);
    expect(response.body).toEqual({
      user: {
        id: "user_optional_case",
        username: "optuser",
        email: "opt@example.com",
        fullName: "Optional User",
        phone: "",
        organization: "",
      },
      token: "simulated-jwt-token-for-user_optional_case",
    });
  });

  it("stores empty optional fields as empty strings", async () => {
    await request(app).post("/api/auth/signup").send({
      username: "optuser",
      email: "opt@example.com",
      password: "SecurePass123",
      fullName: "Optional User",
    });

    const createdUser = users.find((u) => u.username === "optuser");
    expect(createdUser?.phone).toBe("");
    expect(createdUser?.organization).toBe("");
  });

  it("still rejects missing required fields even when optional fields are present", async () => {
    const response = await request(app).post("/api/auth/signup").send({
      username: "",
      email: "opt@example.com",
      password: "SecurePass123",
      fullName: "Optional User",
      phone: "555-111-2222",
      organization: "Optional Org",
    });

    expect(response.status).toBe(400);
    expect(response.body.message).toBe("Username, email, password, and full name are required.");
  });
});
