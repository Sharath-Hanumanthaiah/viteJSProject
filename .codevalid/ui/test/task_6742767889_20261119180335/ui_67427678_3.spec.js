import { test, expect, useMock } from '../../helpers/codevalid-test.js';

test('Newly created event appears in the dashboard registration dropdown', async ({ page }) => {
  test.setTimeout(60000);
  // Given
  await useMock('POST /api/auth/signin', 'default');
  await useMock('GET /api/events', 'default');
  await useMock('GET /api/registrations/:eventId', 'empty');
  await useMock('POST /api/events', 'launch_meetup_active');

  // When: sign in and create the event
  await page.goto('/signin');
  await page.getByPlaceholder('john@example.com').fill('john@example.com');
  await page.getByPlaceholder('••••••••').fill('password123');
  await page.getByRole('button', { name: 'Sign In' }).click();
  await expect(page.getByRole('heading', { name: 'Registration Desk' })).toBeVisible();

  await page.getByRole('navigation').getByRole('link', { name: 'Events Setup' }).first().click();
  await expect(page.getByRole('heading', { name: 'Events Management Setup' })).toBeVisible();
  await page.getByRole('button', { name: 'Create New Event' }).click();
  await page.getByPlaceholder('e.g. Spring Hackathon 2026').fill('CodeValid Launch Meetup');
  await page.getByPlaceholder('Summarize event activities...').fill('Kickoff meetup for the CodeValid community.');
  await page.getByPlaceholder('e.g. Auditorium A or Virtual').fill('Hall B, Berlin');
  await page.locator('input[name="startDate"]').fill('2020-01-01');
  await page.locator('input[name="endDate"]').fill('2099-12-31');
  await page.getByRole('button', { name: 'Publish Event' }).click();
  await expect(page.getByText('Event created successfully!')).toBeVisible();

  // the store now holds the new event
  await useMock('GET /api/events', 'with_launch_meetup_active');
  await useMock('POST /api/registrations', 'launch_meetup_attendee');

  // open the Dashboard
  await page.getByRole('navigation').getByRole('link', { name: 'Registrations' }).first().click();
  await expect(page.getByRole('heading', { name: 'Registration Desk' })).toBeVisible();

  const dropdown = page.getByRole('combobox');
  await expect(dropdown).toContainText('CodeValid Launch Meetup');
  await dropdown.selectOption({ label: 'CodeValid Launch Meetup' });
  await expect(dropdown).toHaveValue('event_cv_active');
  await expect(page.getByText('Registration Active')).toBeVisible();

  await page.getByPlaceholder('Jane Smith').fill('Dana Attendee');
  await page.getByPlaceholder('jane@smith.com').fill('dana@example.com');
  await page.getByPlaceholder('+1 (555) 000-0000').fill('+1 (555) 222-0001');
  await page.getByRole('button', { name: 'Confirm Registration' }).click();

  // Then
  await expect(page.getByText('Attendee registered successfully!')).toBeVisible();
  await expect(page.getByRole('cell', { name: 'Dana Attendee' })).toBeVisible();
  console.log('CODEVALID_TEST_ASSERTION_OK:ui_67427678_3');
});
