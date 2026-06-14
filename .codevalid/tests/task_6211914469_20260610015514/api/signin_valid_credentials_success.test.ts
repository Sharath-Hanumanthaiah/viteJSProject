import express from "express";
import request from "supertest";

type UserRecord = {
  id: string;
  username?: string;
  email: string;
  password: string;
  fullName?: string;
  name?: string;
  phone?: string;
  organization?: string;
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

describe("signin_valid_credentials_success", () => {
  it("authenticates valid credentials and returns user data without password plus token", async () => {
    const app = createSigninApp([
      {
        id: "user-001",
        email: "john.doe@example.com",
        password: "SecurePass123!",
        name: "John Doe",
      },
    ]);

    const response = await request(app)
      .post("/api/auth/signin")
      .send({ email: "john.doe@example.com", password: "SecurePass123!" });

    expect(response.status).toBe(200);
    expect(response.body).toEqual({
      user: {
        id: "user-001",
        email: "john.doe@example.com",
        name: "John Doe",
      },
      token: "simulated-jwt-token-for-user-001",
    });
    expect(response.body.user.password).toBeUndefined();
    expect(response.body.token.startsWith("simulated-jwt-token-for-")).toBe(true);
  });

  it("returns 401 for a valid email with wrong password", async () => {
    const app = createSigninApp([
      {
        id: "user-001",
        email: "john.doe@example.com",
        password: "SecurePass123!",
        name: "John Doe",
      },
    ]);

    const response = await request(app)
      .post("/api/auth/signin")
      .send({ email: "john.doe@example.com", password: "wrong-password" });

    expect(response.status).toBe(401);
    expect(response.body).toEqual({ message: "Invalid email or password." });
  });
});
