import { test, expect, useMock } from '../../helpers/codevalid-test.js';

test('Registration refused for an event outside its date window', async ({ page }) => {
  test.setTimeout(60000);
  // Given
  await useMock('POST /api/auth/signin', 'default');
  await useMock('GET /api/events', 'default');
  await useMock('GET /api/registrations/:eventId', 'empty');
  await useMock('POST /api/events', 'future_conference');
  await useMock('POST /api/registrations', 'not_open_yet');

  // When: sign in and create a future event
  await page.goto('/signin');
  await page.getByPlaceholder('john@example.com').fill('john@example.com');
  await page.getByPlaceholder('••••••••').fill('password123');
  await page.getByRole('button', { name: 'Sign In' }).click();
  await expect(page.getByRole('heading', { name: 'Registration Desk' })).toBeVisible();

  await page.getByRole('navigation').getByRole('link', { name: 'Events Setup' }).first().click();
  await expect(page.getByRole('heading', { name: 'Events Management Setup' })).toBeVisible();
  await page.getByRole('button', { name: 'Create New Event' }).click();
  await page.getByPlaceholder('e.g. Spring Hackathon 2026').fill('Future Robotics Conference');
  await page.getByPlaceholder('Summarize event activities...').fill('Conference on robotics that has not opened yet.');
  await page.getByPlaceholder('e.g. Auditorium A or Virtual').fill('Expo Center, Munich');
  await page.locator('input[name="startDate"]').fill('2099-03-01');
  await page.locator('input[name="endDate"]').fill('2099-03-05');
  await page.getByRole('button', { name: 'Publish Event' }).click();
  await expect(page.getByText('Event created successfully!')).toBeVisible();

  await useMock('GET /api/events', 'with_future_conference');

  // open the Dashboard and select the event
  await page.getByRole('navigation').getByRole('link', { name: 'Registrations' }).first().click();
  await expect(page.getByRole('heading', { name: 'Registration Desk' })).toBeVisible();
  const dropdown = page.getByRole('combobox');
  await expect(dropdown).toContainText('Future Robotics Conference');
  await dropdown.selectOption({ label: 'Future Robotics Conference' });
  await expect(dropdown).toHaveValue('event_cv_future');

  // Then: registration is not permitted
  await expect(page.getByText('Registration Upcoming')).toBeVisible();
  await expect(page.getByText('Registration opens on 2099-03-01.')).toBeVisible();
  await expect(page.getByPlaceholder('Jane Smith')).toBeDisabled();
  await expect(page.getByPlaceholder('jane@smith.com')).toBeDisabled();
  await expect(page.getByPlaceholder('+1 (555) 000-0000')).toBeDisabled();
  await expect(page.getByRole('button', { name: 'Confirm Registration' })).toBeDisabled();
  await expect(page.getByText('Attendee registered successfully!')).toHaveCount(0);
  console.log('CODEVALID_TEST_ASSERTION_OK:ui_67427678_4');
});
