#!/usr/bin/env python3
"""Full-screen Universal Search interface; search execution stays in Bash."""

from __future__ import annotations

import curses
import os
import shutil
import subprocess
import sys
import textwrap
from pathlib import Path


BUILTIN_SITES = [
    ("google", "Google", "g", "Web", "Search the wider web.", "◉"),
    ("youtube", "YouTube", "yt", "Media", "Find videos and channels.", "▶"),
    ("wiki", "Wikipedia", "wiki", "Knowledge", "Explore the free encyclopedia.", "W"),
    ("github", "GitHub", "gh", "Developer", "Find repositories, code and issues.", "◈"),
    ("reddit", "Reddit", "reddit", "Community", "Search discussions and communities.", "◎"),
    ("ddg", "DuckDuckGo", "ddg", "Web", "Search the web with DuckDuckGo.", "◉"),
    ("mdn", "MDN Web Docs", "mdn", "Developer", "Find web platform documentation.", "⌘"),
    ("arch", "Arch Wiki", "arch", "Knowledge", "Search Arch Linux documentation.", "⌘"),
    ("maps", "Google Maps", "maps", "Maps", "Look up places and directions.", "⌖"),
    ("images", "Google Images", "images", "Media", "Discover images across the web.", "▧"),
    ("bing", "Bing", "bing", "Web", "Search the wider web.", "◉"),
    ("brave", "Brave Search", "brave", "Web", "Search with Brave.", "◉"),
    ("npm", "npm", "npm", "Developer", "Find JavaScript packages.", "⬡"),
    ("pypi", "PyPI", "pypi", "Developer", "Find Python packages.", "◆"),
    ("rust", "Rust Docs", "rust", "Knowledge", "Search Rust documentation.", "⌘"),
]

BROWSERS = (
    "firefox", "firefox-esr", "librewolf", "floorp", "brave-browser", "brave",
    "chromium", "chromium-browser", "google-chrome-stable", "google-chrome",
    "vivaldi", "vivaldi-stable", "microsoft-edge-stable", "opera",
)
PRIVATE_FLAGS = {
    "firefox": "--private-window", "firefox-esr": "--private-window",
    "librewolf": "--private-window", "floorp": "--private-window",
    "brave": "--incognito", "brave-browser": "--incognito",
    "chromium": "--incognito", "chromium-browser": "--incognito",
    "google-chrome": "--incognito", "google-chrome-stable": "--incognito",
    "vivaldi": "--incognito", "vivaldi-stable": "--incognito",
    "microsoft-edge": "--inprivate", "microsoft-edge-stable": "--inprivate",
    "opera": "--private", "opera-stable": "--private",
}


def config_dir() -> Path:
    return Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config")) / "universal-search"


def load_settings() -> dict[str, str]:
    values: dict[str, str] = {}
    try:
        for line in (config_dir() / "settings.conf").read_text().splitlines():
            if "=" in line:
                key, value = line.split("=", 1)
                values[key] = value
    except OSError:
        pass
    return values


def save_settings(settings: dict[str, str]) -> None:
    folder = config_dir()
    folder.mkdir(parents=True, exist_ok=True)
    target = folder / "settings.conf"
    temp = target.with_suffix(".tmp")
    temp.write_text("".join(f"{key}={value}\n" for key, value in settings.items()))
    temp.replace(target)


def load_sites() -> list[dict[str, str]]:
    sites = [dict(zip(("id", "label", "alias", "group", "description", "icon"), row))
             for row in BUILTIN_SITES]
    seen = {site[key].lower() for site in sites for key in ("id", "alias")}
    config = config_dir() / "sites.conf"
    try:
        lines = config.read_text().splitlines()
    except OSError:
        lines = []
    for line in lines:
        if not line or line.lstrip().startswith("#"):
            continue
        parts = line.split("|")
        if len(parts) >= 6 and parts[0] == "site":
            _, site_id, label, alias, _url, group = parts[:6]
        elif len(parts) == 4:
            site_id, label, alias, _url = parts
            group = "Custom"
        else:
            continue
        if not site_id or not alias or site_id.lower() in seen or alias.lower() in seen:
            continue
        sites.append({"id": site_id.lower(), "label": label, "alias": alias.lower(),
                      "group": group or "Custom", "description": "Custom search destination.", "icon": "◦"})
        seen.update((site_id.lower(), alias.lower()))
    return sites


def load_favorites(sites: list[dict[str, str]]) -> set[str]:
    path = config_dir() / "favorites"
    if path.exists():
        try:
            return {line.strip().lower() for line in path.read_text().splitlines() if line.strip()}
        except OSError:
            pass
    try:
        values = {line.strip().lower() for line in path.read_text().splitlines() if line.strip()}
        if values:
            return values
    except OSError:
        pass
    return {"google", "github", "youtube"}


def save_favorites(favorites: set[str]) -> None:
    folder = config_dir()
    folder.mkdir(parents=True, exist_ok=True)
    temp = folder / "favorites.tmp"
    temp.write_text("".join(f"{item}\n" for item in sorted(favorites)))
    temp.replace(folder / "favorites")


def available_browsers() -> list[str]:
    return [name for name in BROWSERS if shutil.which(name)]


def prepare_terminal() -> bool:
    if not (sys.stdin.isatty() and sys.stdout.isatty()):
        print("Universal Search needs an interactive terminal.", file=sys.stderr)
        return False
    term = os.environ.get("TERM", "")
    try:
        curses.setupterm(term or None)
    except curses.error:
        pass
    if not term or term == "dumb" or not curses.tigetstr("cup"):
        try:
            curses.setupterm("xterm-256color")
        except curses.error:
            print("Terminal capabilities are missing. Try: export TERM=xterm-256color", file=sys.stderr)
            return False
        os.environ["TERM"] = "xterm-256color"
    return True


def detected_browser() -> str:
    for command in (("xdg-settings", "get", "default-web-browser"),):
        try:
            desktop = subprocess.check_output(command, text=True, stderr=subprocess.DEVNULL, timeout=1).strip().lower()
        except (OSError, subprocess.SubprocessError):
            desktop = ""
        for name in BROWSERS:
            if name.replace("-stable", "") in desktop and shutil.which(name):
                return name
    for name in BROWSERS:
        if shutil.which(name):
            return name
    return ""


class UniversalSearchUI:
    def __init__(self, screen: curses.window, cli_path: str) -> None:
        self.screen = screen
        self.cli_path = cli_path
        self.sites = load_sites()
        self.groups = ["All sites", "Favorites"] + list(dict.fromkeys(site["group"] for site in self.sites))
        self.settings = load_settings()
        self.browser = os.environ.get("UNIVERSAL_SEARCH_BROWSER", self.settings.get("browser", ""))
        self.favorites = load_favorites(self.sites)
        self.category = 0
        self.site = 0
        self.focus = "sites"
        self.filter_text = ""
        self.filtering = False
        self.private = False
        self.picked: set[str] = set()
        self.message = "Ready when you are."
        self.palette = 0
        self._detected_browser: str | None = None
        self.colors = curses.has_colors()
        self._init_colors()

    def _init_colors(self) -> None:
        if not self.colors:
            return
        curses.start_color()
        try:
            curses.use_default_colors()
        except curses.error:
            pass
        bg = -1
        accent = curses.COLOR_CYAN if self.palette == 0 else curses.COLOR_MAGENTA
        try:
            curses.init_pair(1, accent, bg)
            curses.init_pair(2, curses.COLOR_WHITE, curses.COLOR_BLUE)
            curses.init_pair(3, curses.COLOR_BLUE, bg)
            curses.init_pair(4, curses.COLOR_WHITE, bg)
            curses.init_pair(5, curses.COLOR_CYAN, bg)
            curses.init_pair(6, curses.COLOR_YELLOW, bg)
            curses.init_pair(7, curses.COLOR_GREEN, bg)
        except curses.error:
            self.colors = False

    def attr(self, pair: int, bold: bool = False) -> int:
        return (curses.color_pair(pair) if self.colors else 0) | (curses.A_BOLD if bold else 0)

    @staticmethod
    def clipped(window: curses.window, y: int, x: int, text: str, width: int, attr: int = 0) -> None:
        if width <= 0:
            return
        try:
            window.addnstr(y, x, text, width, attr)
        except curses.error:
            pass

    def filtered_sites(self) -> list[dict[str, str]]:
        group = self.groups[self.category]
        result = []
        needle = self.filter_text.casefold()
        for site in self.sites:
            if group == "Favorites" and not self.is_favorite(site):
                continue
            if group != "All sites" and group != "Favorites" and site["group"] != group:
                continue
            if needle and needle not in " ".join((site["id"], site["alias"], site["label"])).casefold():
                continue
            result.append(site)
        if result:
            self.site = max(0, min(self.site, len(result) - 1))
        else:
            self.site = 0
        return result

    def is_favorite(self, site: dict[str, str]) -> bool:
        return site["id"] in self.favorites or site["alias"] in self.favorites

    def private_browser(self) -> tuple[str, bool]:
        if self._detected_browser is None:
            self._detected_browser = detected_browser()
        browser = self.browser or self._detected_browser
        name = Path(browser).name if browser else ""
        if name in PRIVATE_FLAGS and (shutil.which(name) or Path(browser).is_file()):
            return f"{name} · private ready", True
        if not browser:
            return "No private-capable browser detected", False
        return f"{name} has no configured private mode", False

    def panel(self, height: int, width: int, y: int, x: int, title: str, active: bool = False) -> curses.window:
        win = curses.newwin(height, width, y, x)
        try:
            win.box()
            self.clipped(win, 0, 2, f" {title} ", width - 4,
                         self.attr(1 if active else 3, True))
        except curses.error:
            pass
        return win

    def draw(self) -> list[dict[str, str]]:
        self.screen.erase()
        h, w = self.screen.getmaxyx()
        if h < 17 or w < 70:
            self.clipped(self.screen, 1, 2, "Enlarge the terminal to at least 70 × 17 for Universal Search.", w - 4, self.attr(6, True))
            self.screen.refresh()
            return []

        self.clipped(self.screen, 0, 2, "◈  UNIVERSAL SEARCH", w - 4, self.attr(1, True))
        self.clipped(self.screen, 1, 5, "A better way to find your way around the web.", w - 8, self.attr(4))
        if self.filtering:
            filter_label = f"⌕  FILTER  › {self.filter_text}█   Enter finish  Esc clear"
        else:
            filter_label = f"⌕  {self.filter_text or 'Search sites   ·   / to filter'}"
        self.clipped(self.screen, 3, 2, filter_label, w - 4, self.attr(5, True))

        top = 5
        panel_h = h - 9
        side_w = max(20, min(30, w // 5))
        detail_w = max(27, min(40, w // 4))
        mid_w = w - side_w - detail_w - 4
        if mid_w < 24:
            side_w = max(17, side_w - (24 - mid_w))
            mid_w = 24
            detail_w = w - side_w - mid_w - 4
        x_side = 1
        x_mid = x_side + side_w + 1
        x_detail = x_mid + mid_w + 1
        sites = self.filtered_sites()
        current = sites[self.site] if sites else None

        side = self.panel(panel_h, side_w, top, x_side, "CATEGORIES", self.focus == "groups")
        middle = self.panel(panel_h, mid_w, top, x_mid, f"SITES  ·  {len(sites)}", self.focus == "sites")
        detail = self.panel(panel_h, detail_w, top, x_detail, "DETAILS")

        inner_h = panel_h - 2
        for i, group in enumerate(self.groups[:inner_h]):
            count = sum(1 for item in self.sites if
                        (group == "All sites" or (group == "Favorites" and self.is_favorite(item)) or item["group"] == group))
            icons = {"All sites": "▦", "Favorites": "★", "Web": "⌕", "Media": "▶", "Knowledge": "◇", "Developer": "⌘", "Community": "◎", "Maps": "⌖"}
            icon = icons.get(group, "◦")
            label = f"{icon}  {group}  ({count})"
            attr = self.attr(2, True) if i == self.category else self.attr(4)
            if i == self.category:
                label = label.ljust(side_w - 2)
            self.clipped(side, i + 1, 1, label, side_w - 2, attr)

        visible = max(1, inner_h)
        offset = max(0, min(self.site - visible + 1, max(0, len(sites) - visible)))
        for i, item in enumerate(sites[offset:offset + visible]):
            index = offset + i
            icon = item["icon"]
            star = " ★" if self.is_favorite(item) else ""
            selected = index == self.site
            picked = "✓" if item["id"] in self.picked else " "
            label = f"{icon}  {picked}  {item['label']}  [{item['alias']}]{star}"
            attr = self.attr(2, True) if selected else self.attr(4)
            self.clipped(middle, i + 1, 1, label, mid_w - 2, attr)
            if selected:
                try:
                    middle.addnstr(i + 1, 1, label.ljust(mid_w - 2), mid_w - 2, attr)
                except curses.error:
                    pass

        if current:
            private_label, private_ok = self.private_browser()
            self.clipped(detail, 2, 2, current["icon"], detail_w - 4, self.attr(1, True))
            self.clipped(detail, 3, 2, current["label"], detail_w - 4, self.attr(4, True))
            self.clipped(detail, 4, 2, f"{current['group']}  ·  {current['alias']}", detail_w - 4, self.attr(3))
            desc_width = max(10, detail_w - 5)
            desc = textwrap.wrap(current["description"], desc_width) or [current["description"]]
            for line, text in enumerate(desc[:3], start=6):
                self.clipped(detail, line, 2, text, detail_w - 4, self.attr(4))
            separator_y = min(inner_h - 6, 10)
            if separator_y > 0:
                self.clipped(detail, separator_y, 2, "─" * (detail_w - 5), detail_w - 4, self.attr(3))
            self.clipped(detail, separator_y + 1, 2, "SEARCH COMMAND", detail_w - 4, self.attr(1, True))
            self.clipped(detail, separator_y + 2, 2, f"s {current['alias']} <query>", detail_w - 4, self.attr(5))
            fav = "★ In favorites" if self.is_favorite(current) else "☆ Add to favorites"
            self.clipped(detail, separator_y + 4, 2, fav, detail_w - 4, self.attr(6))
            self.clipped(detail, separator_y + 5, 2, f"Browser: {self.browser or 'System default'}", detail_w - 4, self.attr(4))
            self.clipped(detail, separator_y + 6, 2, private_label if self.private else "Normal window", detail_w - 4, self.attr(7 if private_ok else 6))
        else:
            self.clipped(detail, 2, 2, "No destination selected", detail_w - 4, self.attr(6))

        footer_y = h - 3
        status = f"● PRIVATE · {self.private_browser()[0]}" if self.private else "● READY"
        if self.message:
            self.clipped(self.screen, footer_y - 1, 2, self.message, w - 4, self.attr(6))
        self.clipped(self.screen, footer_y, 2, f"{status}   Browser: {self.browser or 'System default'}   {len(self.picked)} selected", w - 4, self.attr(7 if not self.private or self.private_browser()[1] else 6, True))
        if self.filtering:
            controls = "Type filter  Enter done  Esc clear  Q quit"
        else:
            controls = "↑↓ Move  ←→ Panel  Enter Search  / Filter  F Fav  A Add  Q Quit"
        self.clipped(self.screen, h - 2, 2, controls, w - 4, self.attr(5, True))
        self.clipped(self.screen, h - 1, 2, "D Delete  G Category  P Private  B Browser  C Theme  Esc Back", w - 4, self.attr(3))
        # Refresh stdscr first; child panels must overlay its cleared body.
        self.screen.noutrefresh()
        for win in (side, middle, detail):
            win.noutrefresh()
        curses.doupdate()
        return sites

    def toggle_favorite(self, site: dict[str, str] | None) -> None:
        if not site:
            return
        key = site["id"]
        if self.is_favorite(site):
            self.favorites.discard(key)
            self.favorites.discard(site["alias"])
            self.message = f"Removed {site['label']} from favorites."
        else:
            self.favorites.add(key)
            self.message = f"Added {site['label']} to favorites."
        save_favorites(self.favorites)

    def toggle_private(self) -> None:
        self.private = not self.private
        if self.private:
            label, ready = self.private_browser()
            self.message = f"Private mode on · {label}" if ready else f"Private mode on, but {label.lower()}. Press B to choose a browser."
        else:
            self.message = "Private mode off."

    def cycle_browser(self) -> None:
        choices = [""] + available_browsers()
        try:
            current = choices.index(self.browser)
        except ValueError:
            current = 0
        self.browser = choices[(current + 1) % len(choices)]
        self.settings["browser"] = self.browser
        save_settings(self.settings)
        self.message = f"Browser: {self.browser or 'System default'}"

    def prompt_query(self) -> str | None:
        h, w = self.screen.getmaxyx()
        box_w = min(w - 4, max(54, w // 2))
        box_h = 7
        y, x = max(1, (h - box_h) // 2), max(1, (w - box_w) // 2)
        win = curses.newwin(box_h, box_w, y, x)
        win.keypad(True)
        text = ""
        while True:
            win.erase(); win.box()
            self.clipped(win, 1, 2, "NEW SEARCH", box_w - 4, self.attr(1, True))
            self.clipped(win, 2, 2, "Enter a query · Esc to return", box_w - 4, self.attr(3))
            self.clipped(win, 4, 2, f"› {text}█", box_w - 4, self.attr(4, True))
            win.refresh()
            key = win.get_wch()
            if key in ("\x1b",):
                return None
            if key in ("\n", "\r", curses.KEY_ENTER):
                return text.strip() or None
            if key in (curses.KEY_BACKSPACE, "\x7f", "\b"):
                text = text[:-1]
            elif isinstance(key, str) and key.isprintable():
                text += key

    def prompt_add_site(self) -> None:
        labels = (
            "Site ID",
            "Display name",
            "Shortcut alias",
            "Search URL prefix (query is appended)",
            "Category (optional, defaults to Custom)",
        )
        values = ["", "", "", "", ""]
        cursors = [0, 0, 0, 0, 0]
        field = 0
        error = ""
        h, w = self.screen.getmaxyx()
        box_w = min(w - 4, max(58, w // 2 + 12))
        box_h = min(17, h)
        y, x = max(0, (h - box_h) // 2), max(1, (w - box_w) // 2)
        win = curses.newwin(box_h, box_w, y, x)
        win.keypad(True)
        try:
            curses.curs_set(1)
        except curses.error:
            pass

        try:
            while True:
                win.erase()
                win.box()
                self.clipped(win, 1, 2, "ADD A SEARCH SITE", box_w - 4, self.attr(1, True))
                self.clipped(win, 2, 2, "Saved to your user config · existing sites are kept", box_w - 4, self.attr(3))
                for index, label in enumerate(labels):
                    label_y = 4 + index * 2
                    input_y = label_y + 1
                    active = index == field
                    self.clipped(win, label_y, 2, label, box_w - 4, self.attr(1 if active else 3, active))
                    shown = f"› {values[index]}"
                    self.clipped(win, input_y, 2, shown.ljust(box_w - 4), box_w - 4,
                                 self.attr(2 if active else 4, active))
                    if active:
                        cursor_x = min(box_w - 3, 4 + cursors[index])
                        try:
                            win.move(input_y, cursor_x)
                        except curses.error:
                            pass
                self.clipped(win, box_h - 3, 2,
                             error or "Tab/↑↓ next · Enter next/save · ←→ edit · Esc cancel",
                             box_w - 4, self.attr(6 if error else 3))
                win.refresh()
                key = win.get_wch()

                if key == "\x1b":
                    self.message = "Add site cancelled."
                    return
                if key in ("\t", curses.KEY_DOWN):
                    field = (field + 1) % len(labels)
                    error = ""
                    continue
                if key == curses.KEY_BTAB or key == curses.KEY_UP:
                    field = (field - 1) % len(labels)
                    error = ""
                    continue
                if key in ("\n", "\r", curses.KEY_ENTER):
                    if field < len(labels) - 1:
                        field += 1
                        error = ""
                        continue
                    command = [self.cli_path, "--add-site", *values]
                    try:
                        result = subprocess.run(command, text=True, capture_output=True, timeout=10)
                    except (OSError, subprocess.SubprocessError) as exc:
                        error = str(exc)
                        continue
                    if result.returncode:
                        error = result.stderr.strip() or "Could not add this site. Check the fields and try again."
                        continue
                    site_id = values[0].lower()
                    self.sites = load_sites()
                    self.groups = ["All sites", "Favorites"] + list(dict.fromkeys(site["group"] for site in self.sites))
                    self.category = self.groups.index(values[4]) if values[4] in self.groups else 0
                    visible = self.filtered_sites()
                    self.site = next((index for index, site in enumerate(visible) if site["id"] == site_id), 0)
                    self.message = result.stdout.strip() or f"Added {values[1]} to the menu."
                    return

                value = values[field]
                cursor = cursors[field]
                if key in (curses.KEY_BACKSPACE, "\x7f", "\b"):
                    if cursor:
                        values[field] = value[:cursor - 1] + value[cursor:]
                        cursors[field] -= 1
                elif key == curses.KEY_LEFT:
                    cursors[field] = max(0, cursor - 1)
                elif key == curses.KEY_RIGHT:
                    cursors[field] = min(len(value), cursor + 1)
                elif key == curses.KEY_HOME:
                    cursors[field] = 0
                elif key == curses.KEY_END:
                    cursors[field] = len(value)
                elif isinstance(key, str) and key.isprintable():
                    values[field] = value[:cursor] + key + value[cursor:]
                    cursors[field] += len(key)
                error = ""
        finally:
            try:
                curses.curs_set(0)
            except curses.error:
                pass

    def delete_site(self, site: dict[str, str] | None) -> None:
        if not site:
            self.message = "Choose a site to remove."
            return
        if site["id"] in {row[0] for row in BUILTIN_SITES}:
            self.message = "Built-in sites cannot be removed."
            return

        h, w = self.screen.getmaxyx()
        box_w, box_h = min(w - 4, max(52, w // 2)), 7
        y, x = max(1, (h - box_h) // 2), max(1, (w - box_w) // 2)
        win = curses.newwin(box_h, box_w, y, x)
        win.keypad(True)
        win.erase()
        win.box()
        self.clipped(win, 1, 2, "REMOVE CUSTOM SITE", box_w - 4, self.attr(6, True))
        self.clipped(win, 2, 2, f"Delete {site['label']} [{site['alias']}]?", box_w - 4, self.attr(4))
        self.clipped(win, 4, 2, "Y Delete    N / Esc Cancel", box_w - 4, self.attr(3, True))
        win.refresh()
        key = win.get_wch()
        if key not in ("y", "Y"):
            self.message = "Site removal cancelled."
            return

        try:
            result = subprocess.run([self.cli_path, "--remove-site", site["id"]],
                                    text=True, capture_output=True, timeout=10)
        except (OSError, subprocess.SubprocessError) as exc:
            self.message = str(exc)
            return
        if result.returncode:
            self.message = result.stderr.strip() or "Could not remove this site."
            return

        previous_group = self.groups[self.category]
        self.favorites.discard(site["id"])
        self.favorites.discard(site["alias"])
        self.picked.discard(site["id"])
        self.sites = load_sites()
        self.groups = ["All sites", "Favorites"] + list(dict.fromkeys(item["group"] for item in self.sites))
        self.category = self.groups.index(previous_group) if previous_group in self.groups else 0
        visible = self.filtered_sites()
        self.site = min(self.site, max(0, len(visible) - 1))
        self.message = result.stdout.strip() or f"Removed {site['label']} from the menu."

    def launch(self, query: str, sites: list[dict[str, str]]) -> None:
        if not sites:
            self.message = "Choose at least one destination first."
            return
        targets = [site for site in self.sites if site["id"] in self.picked]
        if not targets:
            targets = [sites[self.site]]
        errors = []
        for site in targets:
            command = [self.cli_path]
            if self.private:
                command.append("--private")
            if self.browser:
                command += ["--browser", self.browser]
            command += [site["id"], query]
            try:
                proc = subprocess.run(command, text=True, capture_output=True, timeout=10)
                if proc.returncode:
                    errors.append(proc.stderr.strip() or f"Could not open {site['label']}.")
            except (OSError, subprocess.SubprocessError) as exc:
                errors.append(str(exc))
        self.picked.clear()
        self.message = errors[0] if errors else f"Opened {len(targets)} destination(s)."

    def run(self) -> None:
        curses.cbreak()
        curses.noecho()
        try:
            curses.curs_set(0)
        except curses.error:
            pass
        self.screen.keypad(True)
        self.screen.timeout(-1)
        while True:
            sites = self.draw()
            try:
                key = self.screen.get_wch()
            except curses.error:
                continue
            if key == curses.KEY_RESIZE:
                continue

            if key in ("q", "Q", "\x03"):
                return

            if self.filtering:
                if key in ("\x1b",):
                    self.filtering = False
                    self.filter_text = ""
                    self.site = 0
                elif key in ("\n", "\r", curses.KEY_ENTER):
                    self.filtering = False
                elif key in (curses.KEY_BACKSPACE, "\x7f", "\b"):
                    self.filter_text = self.filter_text[:-1]
                    self.site = 0
                elif isinstance(key, str) and key.isprintable():
                    self.filter_text += key
                    self.site = 0
                continue

            if key in (curses.KEY_UP, "k"):
                if self.focus == "groups":
                    self.category = (self.category - 1) % len(self.groups)
                    self.site = 0
                elif sites:
                    self.site = (self.site - 1) % len(sites)
                continue
            if key in (curses.KEY_DOWN, "j"):
                if self.focus == "groups":
                    self.category = (self.category + 1) % len(self.groups)
                    self.site = 0
                elif sites:
                    self.site = (self.site + 1) % len(sites)
                continue
            if key in (curses.KEY_LEFT,):
                self.focus = "groups"
                continue
            if key in (curses.KEY_RIGHT, "\t", curses.KEY_BTAB):
                self.focus = "sites"
                continue
            if key == curses.KEY_ENTER or key in ("\n", "\r"):
                if self.focus == "groups":
                    self.focus = "sites"
                else:
                    query = self.prompt_query()
                    if query:
                        self.launch(query, sites)
                continue
            if key in ("\x1b",):
                if self.filter_text:
                    self.filter_text = ""
                    self.site = 0
                elif self.focus == "sites":
                    return
                else:
                    self.focus = "sites"
                continue
            if isinstance(key, str):
                if key in ("f", "F"):
                    self.toggle_favorite(sites[self.site] if sites else None)
                elif key in ("p", "P"):
                    self.toggle_private()
                elif key in ("b", "B"):
                    self.cycle_browser()
                elif key in ("g", "G"):
                    self.category = (self.category + 1) % len(self.groups)
                    self.site = 0
                elif key in ("c", "C"):
                    self.palette = 1 - self.palette
                    self._init_colors()
                    self.message = "Theme changed."
                elif key in ("a", "A"):
                    self.prompt_add_site()
                elif key in ("d", "D"):
                    self.delete_site(sites[self.site] if sites else None)
                elif key == "/":
                    self.filtering = True
                    self.message = "Type a site name, then press Enter."
                elif key == " ":
                    if sites:
                        site = sites[self.site]
                        if site["id"] in self.picked:
                            self.picked.remove(site["id"])
                        else:
                            self.picked.add(site["id"])


def main() -> int:
    if len(sys.argv) < 2:
        print("Usage: app.py /path/to/search", file=sys.stderr)
        return 2
    cli_path = str(Path(sys.argv[1]).resolve())
    if not prepare_terminal():
        return 2
    try:
        curses.wrapper(lambda screen: UniversalSearchUI(screen, cli_path).run())
    except KeyboardInterrupt:
        return 130
    except curses.error as exc:
        print(f"Universal Search could not initialize the terminal: {exc}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
