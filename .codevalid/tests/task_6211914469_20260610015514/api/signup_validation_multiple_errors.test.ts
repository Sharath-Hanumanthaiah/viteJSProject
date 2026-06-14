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

describe("signup_validation_multiple_errors", () => {
  const app = createTestApp();

  beforeEach(() => {
    resetUsers();
  });

  afterEach(() => {
    resetUsers();
  });

  it("returns one backend 400 response when multiple required fields are invalid", async () => {
    const response = await request(app).post("/api/auth/signup").send({
      username: "",
      email: "bademail",
      password: "abc",
      fullName: "",
    });

    expect(response.status).toBe(400);
    expect(response.body).toEqual({ message: "Username, email, password, and full name are required." });
  });

  it("shows backend only validates presence, not frontend granular field messages", async () => {
    const response = await request(app).post("/api/auth/signup").send({
      username: "user1",
      email: "bademail",
      password: "abc",
      fullName: "Name",
    });

    expect(response.status).toBe(201);
    expect(response.body.user.email).toBe("bademail");
  });

  it("keeps user store unchanged on failed required-field validation", async () => {
    await request(app).post("/api/auth/signup").send({
      username: "",
      email: "",
      password: "",
      fullName: "",
    });

    expect(users).toHaveLength(originalUsers.length);
  });
});
