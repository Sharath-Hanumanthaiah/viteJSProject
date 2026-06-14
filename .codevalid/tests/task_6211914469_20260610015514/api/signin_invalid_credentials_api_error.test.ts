import { users } from "../../../backend/data/store.js";

const BASE_URL = process.env.CODEVALID_BASE_URL || "http://127.0.0.1:5001";
const baselineUsers = JSON.parse(JSON.stringify(users));

async function postJson(path: string, body: unknown) {
  const response = await fetch(`${BASE_URL}${path}`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify(body),
  });

  const json = await response.json();
  return { response, json };
}

describe("signin_invalid_credentials_api_error", () => {
  beforeEach(() => {
    users.splice(0, users.length, ...JSON.parse(JSON.stringify(baselineUsers)));
  });

  afterEach(() => {
    users.splice(0, users.length, ...JSON.parse(JSON.stringify(baselineUsers)));
  });

  it("returns 401 with the expected error message for a nonexistent email", async () => {
    const { response, json } = await postJson("/api/auth/signin", {
      email: "nonexistent@example.com",
      password: "WrongPassword456",
    });

    expect(response.status).toBe(401);
    expect(json).toEqual({
      message: "Invalid email or password.",
    });
  });

  it("returns 401 with the same message when the password is incorrect for an existing user", async () => {
    users.push({
      id: "user_wrong_password_case",
      username: "realuser",
      email: "real.user@example.com",
      password: "CorrectPassword123",
      fullName: "Real User",
      phone: "",
      organization: "",
    });

    const { response, json } = await postJson("/api/auth/signin", {
      email: "real.user@example.com",
      password: "WrongPassword456",
    });

    expect(response.status).toBe(401);
    expect(json).toEqual({
      message: "Invalid email or password.",
    });
  });
});
