/**
 * Mock data for Playwright tests.
 * Mirrors the shape returned by the real Express backend so tests
 * can run fully isolated without a live API server.
 */

const today = new Date();
const fmt = (d) => d.toISOString().split("T")[0];

export const mockUsers = [
  {
    id: "user_1",
    username: "johndoe",
    email: "john@example.com",
    fullName: "John Doe",
    phone: "+1 (555) 019-2834",
    organization: "Acme Tech Solutions",
  },
  {
    id: "user_2",
    username: "janemiller",
    email: "jane@example.com",
    fullName: "Jane Miller",
    phone: "+1 (555) 014-9876",
    organization: "Innovate Labs",
  },
];

export const mockEvents = [
  {
    id: "event_1",
    title: "Global Tech Summit 2026",
    description:
      "The premier event for AI, cloud computing, and next-gen web technologies.",
    startDate: fmt(new Date(today.getTime() - 2 * 24 * 60 * 60 * 1000)),
    endDate: fmt(new Date(today.getTime() + 5 * 24 * 60 * 60 * 1000)),
    location: "San Francisco, CA & Virtual",
    registrationCount: 2,
  },
  {
    id: "event_2",
    title: "React & Modern Web Design Workshop",
    description:
      "Hands-on workshop focusing on component-based development and high-performance frontend engineering.",
    startDate: fmt(new Date(today.getTime() + 10 * 24 * 60 * 60 * 1000)),
    endDate: fmt(new Date(today.getTime() + 12 * 24 * 60 * 60 * 1000)),
    location: "Austin, TX",
    registrationCount: 0,
  },
  {
    id: "event_3",
    title: "Legacy Backend Systems Seminar",
    description:
      "A deep dive into migrating legacy enterprise databases to modern distributed systems.",
    startDate: fmt(new Date(today.getTime() - 15 * 24 * 60 * 60 * 1000)),
    endDate: fmt(new Date(today.getTime() - 12 * 24 * 60 * 60 * 1000)),
    location: "Online Webcast",
    registrationCount: 0,
  },
];

export const mockRegistrations = {
  event_1: [
    {
      id: "reg_1",
      eventId: "event_1",
      name: "Alice Vance",
      email: "alice@vance.com",
      phone: "+1 (555) 012-3456",
      registeredAt: new Date(today.getTime() - 1 * 24 * 60 * 60 * 1000).toISOString(),
    },
    {
      id: "reg_2",
      eventId: "event_1",
      name: "Bob Builder",
      email: "bob@builder.com",
      phone: "+1 (555) 018-7654",
      registeredAt: new Date(today.getTime() - 12 * 60 * 60 * 1000).toISOString(),
    },
  ],
  event_2: [],
  event_3: [],
};

/** Pre-seeded credentials for the sign-in test */
export const mockCredentials = {
  valid: { email: "john@example.com", password: "password123" },
  invalid: { email: "nobody@nowhere.com", password: "wrongpass" },
};

/** Mock API responses */
export const mockResponses = {
  signIn: {
    success: {
      user: mockUsers[0],
      token: `simulated-jwt-token-for-${mockUsers[0].id}`,
    },
    failure: { message: "Invalid email or password." },
  },
  signUp: {
    success: {
      user: {
        id: "user_new",
        username: "newuser",
        email: "newuser@example.com",
        fullName: "New User",
        phone: "+1 (555) 000-0000",
        organization: "Test Org",
      },
      token: "simulated-jwt-token-for-user_new",
    },
  },
  events: mockEvents,
  registration: {
    success: {
      id: "reg_new",
      eventId: "event_1",
      name: "Test Attendee",
      email: "attendee@test.com",
      phone: "+1 (555) 999-8888",
      registeredAt: new Date().toISOString(),
    },
    duplicate: { message: "This email is already registered for this event." },
  },
};
