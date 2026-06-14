import express from "express";
import request from "supertest";

type UserRecord = {
  id: string;
  email: string;
  password: string;
  username?: string;
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

describe("signin_case_insensitive_email_success", () => {
  it("matches stored email case-insensitively and succeeds", async () => {
    const app = createSigninApp([
      {
        id: "admin-001",
        email: "Admin@Example.COM",
        password: "AdminPass999",
        username: "admin",
      },
    ]);

    const response = await request(app)
      .post("/api/auth/signin")
      .send({ email: "admin@example.com", password: "AdminPass999" });

    expect(response.status).toBe(200);
    expect(response.body).toEqual({
      user: {
        id: "admin-001",
        email: "Admin@Example.COM",
        username: "admin",
      },
      token: "simulated-jwt-token-for-admin-001",
    });
    expect(response.body.user.password).toBeUndefined();
  });

  it("returns 401 if case-insensitive email matches but password is wrong", async () => {
    const app = createSigninApp([
      {
        id: "admin-001",
        email: "Admin@Example.COM",
        password: "AdminPass999",
        username: "admin",
      },
    ]);

    const response = await request(app)
      .post("/api/auth/signin")
      .send({ email: "ADMIN@example.com", password: "wrong-pass" });

    expect(response.status).toBe(401);
    expect(response.body).toEqual({ message: "Invalid email or password." });
  });
});
