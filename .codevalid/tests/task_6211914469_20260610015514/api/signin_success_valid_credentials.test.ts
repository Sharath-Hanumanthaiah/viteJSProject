import { users } from "../../../backend/data/store.js";

const BASE_URL = process.env.CODEVALID_BASE_URL || "http://127.0.0.1:5001";
const baselineUsers = JSON.parse(JSON.stringify(users));

type AuthSuccessResponse = {
  user: {
    id: string;
    username: string;
    email: string;
    fullName: string;
    phone: string;
    organization: string;
    password?: string;
  };
  token: string;
};

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

describe("signin_success_valid_credentials", () => {
  beforeEach(() => {
    users.splice(0, users.length, ...JSON.parse(JSON.stringify(baselineUsers)));
  });

  afterEach(() => {
    users.splice(0, users.length, ...JSON.parse(JSON.stringify(baselineUsers)));
  });

  it("authenticates an existing user and returns a token without exposing the password", async () => {
    users.push({
      id: "user_seed_signin_success",
      username: "johnnydoe",
      email: "john.doe@example.com",
      password: "SecurePass123!",
      fullName: "John Doe",
      phone: "+1 (555) 010-1111",
      organization: "Codevalid",
    });

    const { response, json } = await postJson("/api/auth/signin", {
      email: "john.doe@example.com",
      password: "SecurePass123!",
    });

    const body = json as AuthSuccessResponse;

    expect(response.status).toBe(200);
    expect(body.user).toEqual({
      id: "user_seed_signin_success",
      username: "johnnydoe",
      email: "john.doe@example.com",
      fullName: "John Doe",
      phone: "+1 (555) 010-1111",
      organization: "Codevalid",
    });
    expect(body.user.password).toBeUndefined();
    expect(body.token).toBe("simulated-jwt-token-for-user_seed_signin_success");
  });

  it("accepts email matching case-insensitively for successful signin", async () => {
    users.push({
      id: "user_seed_signin_casefold",
      username: "casefolduser",
      email: "john.doe@example.com",
      password: "SecurePass123!",
      fullName: "John Doe",
      phone: "",
      organization: "",
    });

    const { response, json } = await postJson("/api/auth/signin", {
      email: "JOHN.DOE@EXAMPLE.COM",
      password: "SecurePass123!",
    });

    const body = json as AuthSuccessResponse;

    expect(response.status).toBe(200);
    expect(body.user.email).toBe("john.doe@example.com");
    expect(body.token).toBe("simulated-jwt-token-for-user_seed_signin_casefold");
  });
});
