import express from "express";
import request from "supertest";

type UserRecord = {
  id: string;
  email: string;
  password: string;
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

describe("signin_missing_email_returns_400", () => {
  it("returns 400 when email is missing", async () => {
    const app = createSigninApp([]);

    const response = await request(app)
      .post("/api/auth/signin")
      .send({ password: "somepassword123" });

    expect(response.status).toBe(400);
    expect(response.body).toEqual({ message: "Email and password are required." });
  });

  it("returns 400 when both email and password are missing", async () => {
    const app = createSigninApp([]);

    const response = await request(app).post("/api/auth/signin").send({});

    expect(response.status).toBe(400);
    expect(response.body).toEqual({ message: "Email and password are required." });
  });
});
