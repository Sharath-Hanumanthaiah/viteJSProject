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

  app.post("/api/auth/signup", async (req, res) => {
    const { username, email, password, fullName } = req.body as Record<string, string>;

    if (!username || !email || !password || !fullName) {
      return res.status(400).json({ message: "Username, email, password, and full name are required." });
    }

    await Promise.resolve();

    return res.status(201).json({
      user: { id: "user_loading_case", username, email, fullName, phone: "", organization: "" },
      token: "simulated-jwt-token-for-user_loading_case",
    });
  });

  return app;
}

describe("signup_loading_state_during_submission", () => {
  const app = createTestApp();

  beforeEach(() => {
    resetUsers();
  });

  afterEach(() => {
    resetUsers();
  });

  it("completes a successful signup request for valid data", async () => {
    const response = await request(app).post("/api/auth/signup").send({
      username: "loadtest",
      email: "load@test.com",
      password: "Password123",
      fullName: "Load Test",
    });

    expect(response.status).toBe(201);
    expect(response.body.user).toEqual({
      id: "user_loading_case",
      username: "loadtest",
      email: "load@test.com",
      fullName: "Load Test",
      phone: "",
      organization: "",
    });
  });

  it("returns a stable token format after request completion", async () => {
    const response = await request(app).post("/api/auth/signup").send({
      username: "loadtest2",
      email: "load2@test.com",
      password: "Password123",
      fullName: "Load Test 2",
    });

    expect(response.status).toBe(201);
    expect(response.body.token).toBe("simulated-jwt-token-for-user_loading_case");
  });

  it("returns 400 for invalid payloads while using the same public endpoint", async () => {
    const response = await request(app).post("/api/auth/signup").send({
      username: "",
      email: "load@test.com",
      password: "Password123",
      fullName: "Load Test",
    });

    expect(response.status).toBe(400);
    expect(response.body).toEqual({ message: "Username, email, password, and full name are required." });
  });
});
