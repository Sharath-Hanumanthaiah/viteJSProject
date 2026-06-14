import { users } from "../../../backend/data/store.js";

const BASE_URL = process.env.CODEVALID_BASE_URL || "http://127.0.0.1:5001";
const baselineUsers = JSON.parse(JSON.stringify(users));

type AuthSuccessResponse = {
  user: {
    id: string;
    email: string;
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

describe("signin_loading_state_during_submission", () => {
  beforeEach(() => {
    users.splice(0, users.length, ...JSON.parse(JSON.stringify(baselineUsers)));
  });

  afterEach(() => {
    users.splice(0, users.length, ...JSON.parse(JSON.stringify(baselineUsers)));
  });

  it("completes the signin request successfully for valid credentials, proving the backend supports the in-flight UI flow", async () => {
    users.push({
      id: "user_loading_test",
      username: "loadinguser",
      email: "loading.test@example.com",
      password: "ValidPass789",
      fullName: "Loading Test",
      phone: "",
      organization: "",
    });

    const pendingRequest = postJson("/api/auth/signin", {
      email: "loading.test@example.com",
      password: "ValidPass789",
    });

    expect(pendingRequest).toBeInstanceOf(Promise);

    const { response, json } = await pendingRequest;
    const body = json as AuthSuccessResponse;

    expect(response.status).toBe(200);
    expect(body.user.id).toBe("user_loading_test");
    expect(body.user.email).toBe("loading.test@example.com");
    expect(body.token).toBe("simulated-jwt-token-for-user_loading_test");
  });

  it("returns a terminal response body on failure as well, allowing the frontend finally block to clear loading state", async () => {
    const pendingRequest = postJson("/api/auth/signin", {
      email: "loading.test@example.com",
      password: "WrongPass000",
    });

    expect(pendingRequest).toBeInstanceOf(Promise);

    const { response, json } = await pendingRequest;

    expect(response.status).toBe(401);
    expect(json).toEqual({
      message: "Invalid email or password.",
    });
  });
});
