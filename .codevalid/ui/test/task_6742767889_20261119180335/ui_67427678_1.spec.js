import { test, expect, useMock } from '../../helpers/codevalid-test.js';

test('Create an event from the Events Setup page', async ({ page }) => {
  test.setTimeout(60000);
  // Given
  await useMock('POST /api/auth/signin', 'default');
  await useMock('GET /api/events', 'default');
  await useMock('GET /api/registrations/:eventId', 'default');
  await useMock('POST /api/events', 'launch_meetup_active');

  // When: sign in
  await page.goto('/signin');
  await page.getByPlaceholder('john@example.com').fill('john@example.com');
  await page.getByPlaceholder('••••••••').fill('password123');
  await page.getByRole('button', { name: 'Sign In' }).click();
  await expect(page.getByRole('heading', { name: 'Registration Desk' })).toBeVisible();

  // open Events Setup from the navbar
  await page.getByRole('navigation').getByRole('link', { name: 'Events Setup' }).first().click();
  await expect(page).toHaveURL(/\/events$/);
  await expect(page.getByRole('heading', { name: 'Events Management Setup' })).toBeVisible();

  await page.getByRole('button', { name: 'Create New Event' }).click();
  await page.getByPlaceholder('e.g. Spring Hackathon 2026').fill('CodeValid Launch Meetup');
  await page.getByPlaceholder('Summarize event activities...').fill('Kickoff meetup for the CodeValid community.');
  await page.getByPlaceholder('e.g. Auditorium A or Virtual').fill('Hall B, Berlin');
  await page.locator('input[name="startDate"]').fill('2020-01-01');
  await page.locator('input[name="endDate"]').fill('2099-12-31');
  await page.getByRole('button', { name: 'Publish Event' }).click();

  // Then
  await expect(page.getByText('Event created successfully!')).toBeVisible();
  const card = page.locator('div.glass').filter({ hasText: 'CodeValid Launch Meetup' });
  await expect(card).toHaveCount(1);
  await expect(card).toContainText('Kickoff meetup for the CodeValid community.');
  await expect(card).toContainText('Hall B, Berlin');
  await expect(card).toContainText('2020-01-01 to 2099-12-31');
  console.log('CODEVALID_TEST_ASSERTION_OK:ui_67427678_1');
});
