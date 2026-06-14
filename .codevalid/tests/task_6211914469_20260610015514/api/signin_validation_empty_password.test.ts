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

describe("signin_validation_empty_password", () => {
  beforeEach(() => {
    users.splice(0, users.length, ...JSON.parse(JSON.stringify(baselineUsers)));
  });

  afterEach(() => {
    users.splice(0, users.length, ...JSON.parse(JSON.stringify(baselineUsers)));
  });

  it("returns 400 when password is empty even if email is provided", async () => {
    const { response, json } = await postJson("/api/auth/signin", {
      email: "valid.email@example.com",
      password: "",
    });

    expect(response.status).toBe(400);
    expect(json).toEqual({
      message: "Email and password are required.",
    });
  });

  it("returns the same 400 contract when password is omitted entirely", async () => {
    const { response, json } = await postJson("/api/auth/signin", {
      email: "valid.email@example.com",
    });

    expect(response.status).toBe(400);
    expect(json).toEqual({
      message: "Email and password are required.",
    });
  });
});
