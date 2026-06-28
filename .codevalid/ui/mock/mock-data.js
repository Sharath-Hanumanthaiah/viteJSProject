// Mock data for Playwright test API interception
// This file defines the static mock responses returned by the mock server

const today = new Date();
const formatDate = (date) => date.toISOString().split("T")[0];

export const mockUsers = {
  validUser: {
    id: "user_mock_1",
    username: "testuser",
    email: "test@example.com",
    fullName: "Test User",
    phone: "+1 (555) 123-4567",
    organization: "Test Org",
  },
  token: "simulated-jwt-token-for-user_mock_1",
};

export const mockEvents = [
  {
    id: "event_mock_1",
    title: "Global Tech Summit 2026",
    description:
      "The premier event for AI, cloud computing, and next-gen web technologies.",
    startDate: formatDate(
      new Date(today.getTime() - 2 * 24 * 60 * 60 * 1000)
    ), // started 2 days ago
    endDate: formatDate(
      new Date(today.getTime() + 5 * 24 * 60 * 60 * 1000)
    ), // ends in 5 days
    location: "San Francisco, CA & Virtual",
    registrationCount: 2,
  },
  {
    id: "event_mock_2",
    title: "React & Modern Web Design Workshop",
    description:
      "Hands-on workshop focusing on component-based development and high-performance frontend.",
    startDate: formatDate(
      new Date(today.getTime() + 10 * 24 * 60 * 60 * 1000)
    ), // starts in 10 days
    endDate: formatDate(
      new Date(today.getTime() + 12 * 24 * 60 * 60 * 1000)
    ), // ends in 12 days
    location: "Austin, TX",
    registrationCount: 0,
  },
  {
    id: "event_mock_3",
    title: "Legacy Backend Systems Seminar",
    description:
      "A deep dive into migrating legacy enterprise databases to modern distributed systems.",
    startDate: formatDate(
      new Date(today.getTime() - 15 * 24 * 60 * 60 * 1000)
    ), // started 15 days ago
    endDate: formatDate(
      new Date(today.getTime() - 12 * 24 * 60 * 60 * 1000)
    ), // ended 12 days ago
    location: "Online Webcast",
    registrationCount: 0,
  },
];

export const mockRegistrations = {
  event_mock_1: [
    {
      id: "reg_mock_1",
      eventId: "event_mock_1",
      name: "Alice Vance",
      email: "alice@vance.com",
      phone: "+1 (555) 012-3456",
      registeredAt: new Date(
        today.getTime() - 1 * 24 * 60 * 60 * 1000
      ).toISOString(),
    },
    {
      id: "reg_mock_2",
      eventId: "event_mock_1",
      name: "Bob Builder",
      email: "bob@builder.com",
      phone: "+1 (555) 018-7654",
      registeredAt: new Date(
        today.getTime() - 12 * 60 * 60 * 1000
      ).toISOString(),
    },
  ],
  event_mock_2: [],
  event_mock_3: [],
};

export const mockSigninResponse = {
  user: mockUsers.validUser,
  token: mockUsers.token,
};

export const mockSignupResponse = {
  user: {
    id: "user_mock_new",
    username: "newuser",
    email: "newuser@example.com",
    fullName: "New User",
    phone: "+1 (555) 999-0000",
    organization: "New Org",
  },
  token: "simulated-jwt-token-for-user_mock_new",
};

export const mockNewRegistration = {
  id: "reg_mock_new",
  eventId: "event_mock_1",
  name: "New Attendee",
  email: "newattendee@test.com",
  phone: "+1 (555) 777-8888",
  registeredAt: new Date().toISOString(),
};
