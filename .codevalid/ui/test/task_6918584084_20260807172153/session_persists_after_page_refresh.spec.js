import { test, expect } from '../../helpers/codevalid-test.js';

test('User session persists after refreshing the home page', async ({ page }) => {
  // Given: the user has signed in and is on the protected home page.
  // The app has no Google sign-in button; the session (token in localStorage) is the same
  // regardless of method, so it is established through the Sign In form.
  await page.goto('/signin');
  await page.getByRole('textbox', { name: 'john@example.com' }).fill('john@example.com');
  await page.getByRole('textbox', { name: '••••••••' }).fill('password123');
  await page.getByRole('button', { name: 'Sign In' }).click();

  await expect(page).toHaveURL(/\/$/);
  await expect(page.getByRole('heading', { name: 'Registration Desk' })).toBeVisible();
  await expect(page.getByRole('button', { name: 'Sign Out' })).toBeVisible();

  // When: the browser page is refreshed
  await page.reload();

  // Then: the user stays authenticated, no redirect to sign-in, user content is visible
  await expect(page).toHaveURL(/\/$/);
  await expect(page).not.toHaveURL(/\/signin/);
  await expect(page.getByRole('heading', { name: 'Registration Desk' })).toBeVisible();
  await expect(page.getByRole('button', { name: 'Sign Out' })).toBeVisible();
  await expect(page.getByRole('heading', { name: 'Welcome Back' })).toHaveCount(0);

  console.log('CODEVALID_TEST_ASSERTION_OK:session_persists_after_page_refresh');
});
