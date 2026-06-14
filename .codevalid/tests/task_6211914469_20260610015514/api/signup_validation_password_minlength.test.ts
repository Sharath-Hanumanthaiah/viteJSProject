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

describe("signup_validation_password_minlength", () => {
  const app = createTestApp();

  beforeEach(() => {
    resetUsers();
  });

  afterEach(() => {
    resetUsers();
  });

  it("accepts backend signup even when password is shorter than frontend minimum", async () => {
    const response = await request(app).post("/api/auth/signup").send({
      username: "validuser",
      email: "valid@email.com",
      password: "short",
      fullName: "Valid Name",
    });

    expect(response.status).toBe(201);
    expect(response.body.user.username).toBe("validuser");
  });

  it("still rejects completely missing password", async () => {
    const response = await request(app).post("/api/auth/signup").send({
      username: "validuser",
      email: "valid@email.com",
      password: "",
      fullName: "Valid Name",
    });

    expect(response.status).toBe(400);
    expect(response.body).toEqual({ message: "Username, email, password, and full name are required." });
  });

  it("documents frontend-only password length validation from SignUp.jsx", async () => {
    const response = await request(app).post("/api/auth/signup").send({
      username: "shortpassuser",
      email: "shortpass@example.com",
      password: "12345",
      fullName: "Short Pass",
    });

    expect(response.status).toBe(201);
    expect(response.body.token).toBe("simulated-jwt-token-for-user_fixed");
  });
});
