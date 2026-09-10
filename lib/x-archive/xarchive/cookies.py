from __future__ import annotations

import asyncio
from pathlib import Path

from rich.console import Console
from twscrape import API

console = Console()

X_COOKIE_NAMES = ("auth_token", "ct0")


def cookies_from_browser(browser: str, profile: str | None = None) -> dict[str, str]:
    """
    Read X session cookies from a local browser (same idea as yt-dlp --cookies-from-browser).

    Requires: pip install browser-cookie3 (included in x-archive dependencies).
    On macOS, grant Full Disk Access to Terminal/Cursor if cookie reads fail.
    """
    try:
        import browser_cookie3
    except ImportError as exc:
        raise SystemExit(
            "browser-cookie3 is required. Run: poetry install"
        ) from exc

    loaders = {
        "chrome": browser_cookie3.chrome,
        "chromium": browser_cookie3.chromium,
        "brave": browser_cookie3.brave,
        "firefox": browser_cookie3.firefox,
        "safari": browser_cookie3.safari,
        "edge": browser_cookie3.edge,
    }
    loader = loaders.get(browser.lower())
    if loader is None:
        raise SystemExit(f"Unknown browser {browser!r}. Choose from: {', '.join(loaders)}")

    kwargs: dict = {"domain_name": "x.com"}
    if profile:
        kwargs["profile"] = profile

    found: dict[str, str] = {}
    try:
        jar = loader(**kwargs)
    except Exception as exc:
        raise SystemExit(
            f"Could not read cookies from {browser}: {exc}\n"
            "Ensure you are logged into x.com in that browser. "
            "On macOS, Terminal may need Full Disk Access."
        ) from exc

    for cookie in jar:
        if cookie.name in X_COOKIE_NAMES:
            found[cookie.name] = cookie.value

    if "auth_token" not in found:
        # Some profiles store under twitter.com
        try:
            jar_legacy = loader(domain_name="twitter.com", **({} if not profile else {"profile": profile}))
            for cookie in jar_legacy:
                if cookie.name in X_COOKIE_NAMES:
                    found[cookie.name] = cookie.value
        except Exception:
            pass

    missing = [n for n in X_COOKIE_NAMES if n not in found]
    if missing:
        raise SystemExit(
            f"Missing cookies: {missing}. Log into https://x.com in {browser}, then retry."
        )
    return found


def format_cookie_string(cookies: dict[str, str]) -> str:
    return "; ".join(f"{k}={cookies[k]}" for k in X_COOKIE_NAMES if k in cookies)


async def import_to_twscrape(
    accounts_db: Path,
    username: str,
    cookie_string: str,
    *,
    replace: bool,
) -> None:
    api = API(str(accounts_db))
    existing = await api.pool.get_account(username)
    if existing and not replace:
        raise SystemExit(
            f"Account {username} already exists. Use --replace to overwrite cookies."
        )
    if existing and replace:
        await api.pool.delete_accounts(username)
        console.print(f"Replaced existing account [bold]{username}[/]")

    await api.pool.add_account_cookies(username, cookie_string)
    acc = await api.pool.get_account(username)
    has_ct0 = "ct0" in (acc.cookies if acc else {})
    console.print(
        f"[green]Imported[/] @{username} → {accounts_db} "
        f"(active={acc.active if acc else False}, ct0={'yes' if has_ct0 else 'no'})"
    )
    console.print(
        "[dim]Note: twscrape `accounts` may show logged_in=0 with cookie auth; "
        "that column checks stored headers, not cookie validity.[/]"
    )


async def test_session(accounts_db: Path, probe_user: str = "neoconbill") -> bool:
    """Quick GraphQL probe."""
    api = API(str(accounts_db))
    try:
        user = await api.user_by_login(probe_user)
    except Exception as exc:
        console.print(f"[red]Session test failed:[/] {exc}")
        return False
    if user is None:
        console.print(f"[red]Session test failed:[/] user @{probe_user} not found")
        return False
    console.print(
        f"[green]Session OK[/] — fetched @{user.username} "
        f"({user.statusesCount} posts on profile)"
    )
    return True
