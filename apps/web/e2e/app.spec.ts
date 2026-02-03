import { test, expect } from "@playwright/test";

test.describe("Credora App", () => {
  test("landing page loads", async ({ page }) => {
    await page.goto("/");
    await expect(page.getByRole("heading", { name: /Decentralized Credit/i })).toBeVisible();
    await expect(page.getByRole("link", { name: /Launch App/i })).toBeVisible();
  });

  test("navigates to dashboard", async ({ page }) => {
    await page.goto("/");
    await page.getByRole("link", { name: /Launch App/i }).click();
    await expect(page).toHaveURL(/\/dashboard/);
    await expect(page.getByRole("heading", { name: /Dashboard/i })).toBeVisible();
  });

  test("nav links work", async ({ page }) => {
    await page.goto("/dashboard");
    await page.getByRole("link", { name: /Home/i }).first().click();
    await expect(page).toHaveURL("/");

    await page.getByRole("link", { name: /Score/i }).first().click();
    await expect(page).toHaveURL(/\/score/);

    await page.getByRole("link", { name: /Permissions/i }).first().click();
    await expect(page).toHaveURL(/\/permissions/);
  });

  test("health API returns ok", async ({ request }) => {
    const res = await request.get("http://localhost:3000/api/health");
    expect(res.ok()).toBeTruthy();
    const json = await res.json();
    expect(json.status).toBe("ok");
  });
});
