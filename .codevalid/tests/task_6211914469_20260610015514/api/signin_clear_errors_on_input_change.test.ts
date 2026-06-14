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

describe("signin_clear_errors_on_input_change", () => {
  beforeEach(() => {
    users.splice(0, users.length, ...JSON.parse(JSON.stringify(baselineUsers)));
  });

  afterEach(() => {
    users.splice(0, users.length, ...JSON.parse(JSON.stringify(baselineUsers)));
  });

  it("returns a field-related 400 error before corrected input is submitted and succeeds after valid credentials are sent", async () => {
    users.push({
      id: "user_error_clear_flow",
      username: "errorclear",
      email: "new@example.com",
      password: "SomePassword123",
      fullName: "Error Clear",
      phone: "",
      organization: "",
    });

    const firstAttempt = await postJson("/api/auth/signin", {
      email: "",
      password: "SomePassword123",
    });

    expect(firstAttempt.response.status).toBe(400);
    expect(firstAttempt.json).toEqual({
      message: "Email and password are required.",
    });

    const secondAttempt = await postJson("/api/auth/signin", {
      email: "new@example.com",
      password: "SomePassword123",
    });

    expect(secondAttempt.response.status).toBe(200);
    expect(secondAttempt.json.user.email).toBe("new@example.com");
    expect(secondAttempt.json.token).toBe("simulated-jwt-token-for-user_error_clear_flow");
  });

  it("returns invalid-credentials after corrected-but-unknown input, matching the frontend apiError-clearing and resubmission path", async () => {
    const firstAttempt = await postJson("/api/auth/signin", {
      email: "",
      password: "SomePassword123",
    });

    expect(firstAttempt.response.status).toBe(400);
    expect(firstAttempt.json).toEqual({
      message: "Email and password are required.",
    });

    const secondAttempt = await postJson("/api/auth/signin", {
      email: "new@example.com",
      password: "SomePassword123",
    });

    expect(secondAttempt.response.status).toBe(401);
    expect(secondAttempt.json).toEqual({
      message: "Invalid email or password.",
    });
  });
});
