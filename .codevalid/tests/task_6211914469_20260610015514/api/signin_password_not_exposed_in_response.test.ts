import express from "express";
import request from "supertest";

type UserRecord = {
  id: string;
  email: string;
  password: string;
  fullName?: string;
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

describe("signin_password_not_exposed_in_response", () => {
  it("omits password from the returned user object and response payload", async () => {
    const app = createSigninApp([
      {
        id: "secure-001",
        email: "secure.user@test.com",
        password: "HiddenPass111",
        fullName: "Secure User",
        organization: "Security Org",
      },
    ]);

    const response = await request(app)
      .post("/api/auth/signin")
      .send({ email: "secure.user@test.com", password: "HiddenPass111" });

    expect(response.status).toBe(200);
    expect(response.body.user).toEqual({
      id: "secure-001",
      email: "secure.user@test.com",
      fullName: "Secure User",
      organization: "Security Org",
    });
    expect(response.body.user.password).toBeUndefined();
    expect(JSON.stringify(response.body).includes("HiddenPass111")).toBe(false);
    expect(response.body.token).toBe("simulated-jwt-token-for-secure-001");
  });

  it("still rejects invalid credentials with 401 and does not leak password", async () => {
    const app = createSigninApp([
      {
        id: "secure-001",
        email: "secure.user@test.com",
        password: "HiddenPass111",
        fullName: "Secure User",
      },
    ]);

    const response = await request(app)
      .post("/api/auth/signin")
      .send({ email: "secure.user@test.com", password: "bad-pass" });

    expect(response.status).toBe(401);
    expect(response.body).toEqual({ message: "Invalid email or password." });
    expect(JSON.stringify(response.body).includes("HiddenPass111")).toBe(false);
  });
});
