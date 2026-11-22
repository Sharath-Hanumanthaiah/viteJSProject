import { test, expect } from '../../helpers/codevalid-test.js';

test('Unauthenticated visitor is redirected from Events Setup', async ({ page }) => {
  // Given: signed out
  await page.goto('/signin');
  await page.evaluate(() => { localStorage.removeItem('user'); localStorage.removeItem('token'); });

  // When
  await page.goto('/events');

  // Then
  await expect(page).toHaveURL(/\/signin$/);
  await expect(page.getByRole('heading', { name: 'Welcome Back' })).toBeVisible();
  await expect(page.getByRole('button', { name: 'Sign In' })).toBeVisible();
  await expect(page.getByRole('heading', { name: 'Events Management Setup' })).toHaveCount(0);
  await expect(page.getByRole('link', { name: 'Events Setup' })).toHaveCount(0);
  console.log('CODEVALID_TEST_ASSERTION_OK:ui_67427678_2');
});
