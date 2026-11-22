import { test, expect } from '../../helpers/codevalid-test.js';

test('Unauthenticated access to /home redirects to the sign-in page', async ({ page }) => {
  // Given: no session (fresh context, empty localStorage)
  // When: the visitor opens a protected URL directly
  await page.goto('/home');

  // Then: the app redirects to its sign-in route (/signin in src/App.jsx)
  await expect(page).toHaveURL(/\/signin$/);
  await expect(page.getByRole('heading', { name: 'Welcome Back' })).toBeVisible();
  await expect(page.getByRole('button', { name: 'Sign In' })).toBeVisible();

  // No protected content is shown
  await expect(page.getByRole('heading', { name: 'Registration Desk' })).toHaveCount(0);
  await expect(page.getByRole('navigation')).toHaveCount(0);
  await expect(page.getByRole('button', { name: 'Sign Out' })).toHaveCount(0);

  console.log('CODEVALID_TEST_ASSERTION_OK:redirect_to_login_from_protected_route');
});
