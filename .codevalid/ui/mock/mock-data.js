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

// ---------------------------------------------------------------------------
// Auth session fixture
// Used by helpers/mock-api.js: setupAuthenticatedSession, mockSuccessfulSigninFlow, etc.
// Shape: { token, user } — injected into localStorage
// ---------------------------------------------------------------------------
export const authSession = {
  token: "simulated-jwt-token-for-user_codevalid001",
  user: {
    id: "user_codevalid001",
    username: "testuser",
    email: "testuser@example.com",
    fullName: "Test User",
  },
};

// ---------------------------------------------------------------------------
// Empty events list
// Used as initial state before any events are created.
// ---------------------------------------------------------------------------
export const emptyEvents = [];

// ---------------------------------------------------------------------------
// validUpcomingEvent
// An event that is currently active (startDate in the past, endDate in the future).
// Used by multiple registration tests; .id is accessed for payload assertions.
// ---------------------------------------------------------------------------
export const validUpcomingEvent = {
  id: "event_upcoming001",
  title: "Upcoming Tech Summit",
  description: "A live technology summit open for registration.",
  startDate: "2024-01-01",
  endDate: "2099-12-31",
  location: "Convention Center",
  registrationCount: 0,
};

// ---------------------------------------------------------------------------
// successfulRegistration
// Returned by the mock POST /api/registrations endpoint on success.
// ---------------------------------------------------------------------------
export const successfulRegistration = {
  id: "reg_success001",
  eventId: "event_upcoming001",
  name: "Jane Smith",
  email: "jane@smith.com",
  phone: "+1 (555) 000-0000",
  registeredAt: "2026-06-01T10:00:00.000Z",
};

// ---------------------------------------------------------------------------
// futureRegistrationEvent
// Registration not yet open; startDate is in the future.
// .startDate is used in "Registration opens on <startDate>." assertion.
// ---------------------------------------------------------------------------
export const futureRegistrationEvent = {
  id: "event_future001",
  title: "Future Dev Conference",
  description: "Coming soon — registration not open yet.",
  startDate: "2099-01-01",
  endDate: "2099-12-31",
  location: "Tech Hub",
  registrationCount: 0,
};

// ---------------------------------------------------------------------------
// closedPastEvent
// Registration closed; endDate is in the past.
// .endDate is used in "Registration closed on <endDate>." assertion.
// ---------------------------------------------------------------------------
export const closedPastEvent = {
  id: "event_closed001",
  title: "Past Developers Meetup",
  description: "This event has already ended.",
  startDate: "2020-01-01",
  endDate: "2020-01-02",
  location: "Old Town Hall",
  registrationCount: 5,
};

// ---------------------------------------------------------------------------
// techSummitEvent
// Used to verify event card metadata display.
// Tests assert: title "Tech Summit", description contains "Annual conference",
// location "San Francisco", startDate "2024-06-01", endDate "2024-06-03".
// ---------------------------------------------------------------------------
export const techSummitEvent = {
  id: "event_techsummit001",
  title: "Tech Summit",
  description: "Annual conference for technology leaders and innovators.",
  startDate: "2024-06-01",
  endDate: "2024-06-03",
  location: "San Francisco",
  registrationCount: 0,
};

// ---------------------------------------------------------------------------
// eventAZeroRegistrations / eventBThreeRegistrations
// Used to verify registration counts shown in event select/list.
// Test selects by eventBThreeRegistrations.id; asserts "Hall Beta" visible for B.
// ---------------------------------------------------------------------------
export const eventAZeroRegistrations = {
  id: "event_count_a001",
  title: "Event A",
  description: "Event A with zero registrations.",
  startDate: "2024-01-01",
  endDate: "2099-12-31",
  location: "Hall Alpha",
  registrationCount: 0,
};

export const eventBThreeRegistrations = {
  id: "event_count_b001",
  title: "Event B",
  description: "Event B with three registrations.",
  startDate: "2024-01-01",
  endDate: "2099-12-31",
  location: "Hall Beta",
  registrationCount: 3,
};

// ---------------------------------------------------------------------------
// persistedEventOne / persistedEventTwo
// Used to verify events persist across page navigation.
// Tests assert: "Architecture Review", "Customer Demo Day",
// "2 registered", "4 registered", and chronological card order.
// ---------------------------------------------------------------------------
export const persistedEventOne = {
  id: "event_persist001",
  title: "Architecture Review",
  description: "System architecture review session.",
  startDate: "2024-03-01",
  endDate: "2024-03-01",
  location: "Room 101",
  registrationCount: 2,
};

export const persistedEventTwo = {
  id: "event_persist002",
  title: "Customer Demo Day",
  description: "Live demo day for customers.",
  startDate: "2024-03-02",
  endDate: "2024-03-02",
  location: "Auditorium",
  registrationCount: 4,
};

// ---------------------------------------------------------------------------
// refreshCreatedEvent
// Returned by mock POST /api/events in the auto-refresh-after-create test.
// ---------------------------------------------------------------------------
export const refreshCreatedEvent = {
  id: "event_refresh001",
  title: "Release Planning Session",
  description: "Quarterly roadmap alignment",
  startDate: "2024-08-05",
  endDate: "2024-08-05",
  location: "HQ Board Room",
  registrationCount: 0,
};

// ---------------------------------------------------------------------------
// createdSpringHackathonEvent
// Returned by mock POST /api/events in the create-and-retrieve test.
// ---------------------------------------------------------------------------
export const createdSpringHackathonEvent = {
  id: "event_hackathon001",
  title: "Spring Hackathon 2026",
  description: "Build and demo event prototypes over two days.",
  startDate: "2026-06-11",
  endDate: "2026-06-18",
  location: "Auditorium A",
  registrationCount: 0,
};

// ---------------------------------------------------------------------------
// annualConferenceEvent
// Returned by mock POST /api/events in the all-fields creation test.
// ---------------------------------------------------------------------------
export const annualConferenceEvent = {
  id: "event_annual001",
  title: "Annual Conference",
  description: "Annual tech event for developers",
  startDate: "2024-06-15",
  endDate: "2024-06-17",
  location: "Convention Center, New York",
  registrationCount: 0,
};

// ---------------------------------------------------------------------------
// lunchAndLearnEvent
// Returned by mock POST /api/events in the optional-description test.
// description is empty to simulate "No description provided." fallback.
// ---------------------------------------------------------------------------
export const lunchAndLearnEvent = {
  id: "event_lunchandlearn001",
  title: "Lunch & Learn",
  description: "",
  startDate: "2024-07-01",
  endDate: "2024-07-01",
  location: "Cafeteria",
  registrationCount: 0,
};

// ---------------------------------------------------------------------------
// registrationUserA / registrationUserB
// Used in the multiple-users-register-same-event test.
// .email is used in de-duplication logic.
// ---------------------------------------------------------------------------
export const registrationUserA = {
  id: "reg_userA001",
  eventId: "event_upcoming001",
  name: "User A",
  email: "a@example.com",
  phone: "+1 (555) 202-0001",
  registeredAt: "2026-06-01T10:00:00.000Z",
};

export const registrationUserB = {
  id: "reg_userB001",
  eventId: "event_upcoming001",
  name: "User B",
  email: "b@example.com",
  phone: "+1 (555) 202-0002",
  registeredAt: "2026-06-01T11:00:00.000Z",
};

// ---------------------------------------------------------------------------
// existingRegistrationForDuplicateEmail
// Used in the duplicate-email-blocked test.
// Test asserts "user@example.com" is visible in the registration list.
// ---------------------------------------------------------------------------
export const existingRegistrationForDuplicateEmail = {
  id: "reg_dup001",
  eventId: "event_upcoming001",
  name: "Existing User",
  email: "user@example.com",
  phone: "+1 (555) 111-2222",
  registeredAt: "2026-05-01T09:00:00.000Z",
};

// ---------------------------------------------------------------------------
// eventX / eventY
// Used to verify registration counts are displayed per event card on /events.
// eventX has 3 registrations, eventY has 1.
// ---------------------------------------------------------------------------
export const eventX = {
  id: "event_x001",
  title: "Event X",
  description: "Event X description.",
  startDate: "2024-05-01",
  endDate: "2099-12-31",
  location: "Location X",
  registrationCount: 3,
};

export const eventY = {
  id: "event_y001",
  title: "Event Y",
  description: "Event Y description.",
  startDate: "2024-05-02",
  endDate: "2099-12-31",
  location: "Location Y",
  registrationCount: 1,
};

// ---------------------------------------------------------------------------
// eventA / eventB / eventC
// Used in the sorted-by-date test.
// setupEventCreationScenario sorts by startDate ascending, so the rendered
// order must be ["Event B", "Event A", "Event C"].
// Therefore: eventB.startDate < eventA.startDate < eventC.startDate
// ---------------------------------------------------------------------------
export const eventA = {
  id: "event_sort_a001",
  title: "Event A",
  description: "Sort test event A.",
  startDate: "2024-06-15",
  endDate: "2024-06-16",
  location: "Venue A",
  registrationCount: 0,
};

export const eventB = {
  id: "event_sort_b001",
  title: "Event B",
  description: "Sort test event B — earliest date.",
  startDate: "2024-06-01",
  endDate: "2024-06-02",
  location: "Venue B",
  registrationCount: 0,
};

export const eventC = {
  id: "event_sort_c001",
  title: "Event C",
  description: "Sort test event C — latest date.",
  startDate: "2024-07-01",
  endDate: "2024-07-02",
  location: "Venue C",
  registrationCount: 0,
};

// ---------------------------------------------------------------------------
// validDisplayEvent / malformedHiddenEvent
// Used to verify only valid events appear in the registration dropdown.
// validDisplayEvent is returned by the API; malformedHiddenEvent is not —
// the test asserts its title has count 0.
// .title and .location are accessed directly.
// ---------------------------------------------------------------------------
export const validDisplayEvent = {
  id: "event_display001",
  title: "Valid Display Event",
  description: "This event should appear in the registration list.",
  startDate: "2024-01-01",
  endDate: "2099-12-31",
  location: "Main Hall",
  registrationCount: 0,
};

export const malformedHiddenEvent = {
  id: "event_hidden001",
  title: "Hidden Malformed Event",
  description: "",
  startDate: "",
  endDate: "",
  location: "Unknown",
  registrationCount: 0,
};
