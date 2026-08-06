export const authUser = {
  id: "user-1",
  username: "johndoe",
  email: "john@example.com",
  fullName: "John Doe",
  phone: "+1 (555) 000-0000",
  organization: "Acme Corp",
};

export const authSession = {
  user: authUser,
  token: "mock-valid-token",
};

export const emptyEvents = [];

export const createdSpringHackathonEvent = {
  id: "event-spring-hackathon-2026",
  title: "Spring Hackathon 2026",
  description: "Build and demo event prototypes over two days.",
  startDate: "2026-06-11",
  endDate: "2026-06-18",
  location: "Auditorium A",
  registrationCount: 0,
};

export const eventAZeroRegistrations = {
  id: "event-a-zero",
  title: "Event A",
  description: "Team kickoff event",
  startDate: "2026-06-10",
  endDate: "2026-06-10",
  location: "Hall Alpha",
  registrationCount: 0,
};

export const eventBThreeRegistrations = {
  id: "event-b-three",
  title: "Event B",
  description: "Workshop with attendees",
  startDate: "2026-06-12",
  endDate: "2026-06-12",
  location: "Hall Beta",
  registrationCount: 3,
};

export const validUpcomingEvent = {
  id: "event-valid-upcoming",
  title: "Community Meetup",
  description: "Open networking session",
  startDate: "2024-01-01",
  endDate: "2099-12-31",
  location: "Innovation Hub",
  registrationCount: 0,
};

export const successfulRegistration = {
  id: "reg-success-1",
  eventId: "event-valid-upcoming",
  name: "Jane Smith",
  email: "jane@smith.com",
  phone: "+1 (555) 000-0000",
  registeredAt: "2026-06-10T10:00:00.000Z",
};

export const futureRegistrationEvent = {
  id: "event-registration-future",
  title: "Future Planning Summit",
  description: "Planning session before registration opens",
  startDate: "2099-12-20",
  endDate: "2099-12-27",
  location: "North Campus",
  registrationCount: 0,
};

export const closedPastEvent = {
  id: "event-registration-closed",
  title: "Past Expo",
  description: "Already completed event",
  startDate: "2020-01-10",
  endDate: "2020-01-17",
  location: "Legacy Hall",
  registrationCount: 0,
};

export const existingRegistrationForDuplicateEmail = {
  id: "reg-duplicate-1",
  eventId: "event-valid-upcoming",
  name: "Existing User",
  email: "user@example.com",
  phone: "+1 (555) 111-2222",
  registeredAt: "2026-06-10T09:00:00.000Z",
};

export const registrationUserA = {
  id: "reg-user-a",
  eventId: "event-valid-upcoming",
  name: "User A",
  email: "a@example.com",
  phone: "+1 (555) 202-0001",
  registeredAt: "2026-06-10T09:30:00.000Z",
};

export const registrationUserB = {
  id: "reg-user-b",
  eventId: "event-valid-upcoming",
  name: "User B",
  email: "b@example.com",
  phone: "+1 (555) 202-0002",
  registeredAt: "2026-06-10T09:45:00.000Z",
};

export const validDisplayEvent = {
  id: "event-valid-display",
  title: "Event A",
  description: "Valid event for registration",
  startDate: "2024-01-01",
  endDate: "2099-12-31",
  location: "City Center",
  registrationCount: 0,
};

export const malformedHiddenEvent = {
  id: "event-hidden-invalid",
  title: "Event B",
  description: "Invalid event filtered out by backend",
  startDate: "2026-06-20",
  endDate: "2026-06-10",
  location: "Nowhere",
  registrationCount: 0,
};

export const techSummitEvent = {
  id: "event-tech-summit",
  title: "Tech Summit",
  description: "Annual conference",
  startDate: "2024-06-01",
  endDate: "2024-06-03",
  location: "San Francisco",
  registrationCount: 0,
};
