"""
Optional: export Playwright storage_state after manual X login.

Usage (requires dev dependency: poetry install --with dev && playwright install chromium):

    poetry run python -m xarchive.playwright_export

Writes storage_state.json in the x-archive project root (gitignored).
twscrape typically uses accounts.db via `twscrape add_cookie`; use this script
only if you need a browser session snapshot for debugging or custom tooling.
"""

from __future__ import annotations

import asyncio
from pathlib import Path

from rich.console import Console

console = Console()
OUTPUT = Path(__file__).resolve().parent.parent / "storage_state.json"


async def export_storage_state() -> None:
    try:
        from playwright.async_api import async_playwright
    except ImportError as exc:
        raise SystemExit(
            "Playwright not installed. Run: poetry install --with dev && playwright install chromium"
        ) from exc

    console.print("[bold]Log in to X in the browser window, then press Enter here.[/]")
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=False)
        context = await browser.new_context()
        page = await context.new_page()
        await page.goto("https://x.com/login")
        await asyncio.to_thread(input, "Press Enter after login… ")
        await context.storage_state(path=str(OUTPUT))
        await browser.close()
    console.print(f"[green]Saved[/] {OUTPUT}")
    console.print(
        "For twscrape, prefer: twscrape add_cookie <username> \"auth_token=…; ct0=…\""
    )


def main() -> None:
    asyncio.run(export_storage_state())


if __name__ == "__main__":
    main()
