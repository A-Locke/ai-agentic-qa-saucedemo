import { test, expect } from "@playwright/test";

test("seed: login as standard_user", async ({ page }) => {
  await page.goto("https://www.saucedemo.com/");

  // Use resilient selectors (data-test attributes exist on SauceDemo)
  await page.getByTestId("username").fill("standard_user");
  await page.getByTestId("password").fill("secret_sauce");
  await page.getByTestId("login-button").click();

  await expect(page).toHaveURL(/.*inventory\.html/);
  await expect(page.getByText("Products")).toBeVisible();
});