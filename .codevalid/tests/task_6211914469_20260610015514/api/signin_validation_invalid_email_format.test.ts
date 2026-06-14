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

describe("signin_validation_invalid_email_format", () => {
  beforeEach(() => {
    users.splice(0, users.length, ...JSON.parse(JSON.stringify(baselineUsers)));
  });

  afterEach(() => {
    users.splice(0, users.length, ...JSON.parse(JSON.stringify(baselineUsers)));
  });

  it("returns 401 for an invalid-format email that passes backend required-field validation but matches no user", async () => {
    const { response, json } = await postJson("/api/auth/signin", {
      email: "invalid-email-format",
      password: "SomePassword123",
    });

    expect(response.status).toBe(401);
    expect(json).toEqual({
      message: "Invalid email or password.",
    });
  });

  it("still returns the same invalid-credentials response for another malformed email string", async () => {
    const { response, json } = await postJson("/api/auth/signin", {
      email: "no-at-symbol.example.com",
      password: "SomePassword123",
    });

    expect(response.status).toBe(401);
    expect(json).toEqual({
      message: "Invalid email or password.",
    });
  });
});
