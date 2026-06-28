/**
 * Mock data for CodeValid UI tests.
 * Provides realistic fixture data for all API endpoints:
 *   POST /api/auth/signin
 *   POST /api/auth/signup
 *   GET  /api/events
 *   POST /api/events
 *   GET  /api/registrations/:eventId
 *   POST /api/registrations
 */

export const mockUser = {
  id: "user_codevalid001",
  username: "testuser",
  email: "testuser@example.com",
  fullName: "Test User",
  phone: "+1 (555) 000-0001",
  organization: "CodeValid QA",
};

export const mockToken = "simulated-jwt-token-for-user_codevalid001";

export const mockEvents = [
  {
    id: "event_codevalid001",
    title: "Tech Conference 2026",
    description: "Annual technology conference covering AI, cloud, and DevOps.",
    startDate: "2026-01-01",
    endDate: "2099-12-31",
    location: "San Francisco, CA",
    registrationCount: 2,
  },
  {
    id: "event_codevalid002",
    title: "Design Sprint Workshop",
    description: "Hands-on design sprint workshop for product teams.",
    startDate: "2026-01-01",
    endDate: "2099-12-31",
    location: "New York, NY",
    registrationCount: 0,
  },
];

export const mockRegistrations = {
  event_codevalid001: [
    {
      id: "reg_codevalid001",
      eventId: "event_codevalid001",
      name: "Alice Johnson",
      email: "alice@example.com",
      phone: "+1 (555) 100-0001",
      registeredAt: "2026-06-01T10:00:00.000Z",
    },
    {
      id: "reg_codevalid002",
      eventId: "event_codevalid001",
      name: "Bob Smith",
      email: "bob@example.com",
      phone: "+1 (555) 100-0002",
      registeredAt: "2026-06-02T11:00:00.000Z",
    },
  ],
  event_codevalid002: [],
};

export const mockNewRegistration = {
  id: "reg_codevalid_new",
  eventId: "event_codevalid001",
  name: "Charlie Brown",
  email: "charlie@example.com",
  phone: "+1 (555) 200-0001",
  registeredAt: new Date().toISOString(),
};
