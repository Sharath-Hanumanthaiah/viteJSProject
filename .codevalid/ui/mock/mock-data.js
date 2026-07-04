/**
 * mock-data.js
 * -----------
 * Centralised in-memory fixture data for the mock API server.
 * Mirrors the shape used by backend/data/store.js so Playwright tests
 * can exercise the full UI without a real Express backend.
 */

export const mockUsers = [
  {
    id: "user_test001",
    username: "testuser",
    email: "test@example.com",
    password: "password123",
    fullName: "Test User",
    phone: "555-0100",
    organization: "CodeValid QA",
  },
  {
    id: "user_admin001",
    username: "admin",
    email: "admin@example.com",
    password: "adminpass",
    fullName: "Admin User",
    phone: "555-0200",
    organization: "CodeValid",
  },
];

const today = new Date();
const fmt = (d) => d.toISOString().split("T")[0];

export const mockEvents = [
  {
    id: "event_001",
    title: "Tech Conference 2026",
    description: "Annual technology conference covering AI, cloud, and DevOps.",
    startDate: fmt(today),
    endDate: fmt(new Date(today.getTime() + 2 * 24 * 60 * 60 * 1000)),
    location: "San Francisco, CA",
    registrationCount: 2,
  },
  {
    id: "event_002",
    title: "React & Frontend Summit",
    description: "A deep dive into modern frontend development with React.",
    startDate: fmt(today),
    endDate: fmt(new Date(today.getTime() + 1 * 24 * 60 * 60 * 1000)),
    location: "New York, NY",
    registrationCount: 1,
  },
  {
    id: "event_003",
    title: "DevOps Days",
    description: "Continuous integration, delivery, and monitoring best practices.",
    startDate: fmt(new Date(today.getTime() + 7 * 24 * 60 * 60 * 1000)),
    endDate: fmt(new Date(today.getTime() + 9 * 24 * 60 * 60 * 1000)),
    location: "Austin, TX",
    registrationCount: 0,
  },
];

export const mockRegistrations = [
  {
    id: "reg_001",
    eventId: "event_001",
    name: "Alice Smith",
    email: "alice@example.com",
    phone: "555-1001",
    registeredAt: new Date().toISOString(),
  },
  {
    id: "reg_002",
    eventId: "event_001",
    name: "Bob Jones",
    email: "bob@example.com",
    phone: "555-1002",
    registeredAt: new Date().toISOString(),
  },
  {
    id: "reg_003",
    eventId: "event_002",
    name: "Carol White",
    email: "carol@example.com",
    phone: "555-1003",
    registeredAt: new Date().toISOString(),
  },
];

/**
 * Canonical mock API responses keyed by endpoint pattern.
 * Used by mock-server.js to construct route handlers.
 */
export const mockResponses = {
  /** POST /api/auth/signin – success */
  signinSuccess: (user) => ({
    user: {
      id: user.id,
      username: user.username,
      email: user.email,
      fullName: user.fullName,
      phone: user.phone,
      organization: user.organization,
    },
    token: `simulated-jwt-token-for-${user.id}`,
  }),

  /** POST /api/auth/signin – failure */
  signinFailure: {
    message: "Invalid email or password.",
  },

  /** POST /api/auth/signup – success */
  signupSuccess: (user) => ({
    user: {
      id: user.id,
      username: user.username,
      email: user.email,
      fullName: user.fullName,
      phone: user.phone,
      organization: user.organization,
    },
    token: `simulated-jwt-token-for-${user.id}`,
  }),

  /** POST /api/auth/signup – duplicate user */
  signupDuplicate: {
    message: "Username or Email already registered.",
  },

  /** GET /api/events */
  eventsList: mockEvents,

  /** POST /api/events – success */
  eventCreated: (event) => ({ ...event, registrationCount: 0 }),

  /** GET /api/registrations/:eventId */
  registrationsList: (eventId) =>
    mockRegistrations.filter((r) => r.eventId === eventId),

  /** POST /api/registrations – success */
  registrationCreated: (data) => ({
    id: `reg_${Math.random().toString(36).substr(2, 6)}`,
    ...data,
    registeredAt: new Date().toISOString(),
  }),

  /** POST /api/registrations – already registered */
  registrationDuplicate: {
    message: "This email is already registered for this event.",
  },

  /** 404 fallback */
  notFound: { message: "Not found." },

  /** 400 validation error */
  validationError: (msg) => ({ message: msg }),
};
