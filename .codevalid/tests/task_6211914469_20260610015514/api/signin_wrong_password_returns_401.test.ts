import express from "express";
import request from "supertest";

type UserRecord = {
  id: string;
  email: string;
  password: string;
  fullName?: string;
};

function createSigninApp(seedUsers: UserRecord[]) {
  const app = express();
  app.use(express.json());

  const users = [...seedUsers];

  app.post("/api/auth/signin", (req, res) => {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ message: "Email and password are required." });
    }

    const user = users.find((u) => u.email.toLowerCase() === String(email).toLowerCase());

    if (!user || user.password !== password) {
      return res.status(401).json({ message: "Invalid email or password." });
    }

    const { password: _password, ...userWithoutPassword } = user;
    return res.status(200).json({
      user: userWithoutPassword,
      token: `simulated-jwt-token-for-${user.id}`,
    });
  });

  return app;
}

describe("signin_wrong_password_returns_401", () => {
  it("returns 401 when password is incorrect for an existing user", async () => {
    const app = createSigninApp([
      {
        id: "jane-001",
        email: "jane.smith@example.com",
        password: "CorrectPass456",
        fullName: "Jane Smith",
      },
    ]);

    const response = await request(app)
      .post("/api/auth/signin")
      .send({ email: "jane.smith@example.com", password: "WrongPassword789" });

    expect(response.status).toBe(401);
    expect(response.body).toEqual({ message: "Invalid email or password." });
  });

  it("returns 200 when the same user provides the correct password", async () => {
    const app = createSigninApp([
      {
        id: "jane-001",
        email: "jane.smith@example.com",
        password: "CorrectPass456",
        fullName: "Jane Smith",
      },
    ]);

    const response = await request(app)
      .post("/api/auth/signin")
      .send({ email: "jane.smith@example.com", password: "CorrectPass456" });

    expect(response.status).toBe(200);
    expect(response.body.user).toEqual({
      id: "jane-001",
      email: "jane.smith@example.com",
      fullName: "Jane Smith",
    });
    expect(response.body.user.password).toBeUndefined();
    expect(response.body.token).toBe("simulated-jwt-token-for-jane-001");
  });
});
