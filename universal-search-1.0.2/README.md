# Universal Search 1.0.8

A Bash web-search launcher with a Python `curses` app-style terminal interface, site groups, favorites and custom site support. Bash continues to handle command-line searches; Python `curses` draws the interactive three-panel menu without a third-party Python library.

The interactive menu uses the Python 3 `curses` module. Debian and Arch packages declare its runtime dependency; the local installer uses it when available and falls back to the Bash menu otherwise.

## Run

```bash
./search --help
./search github bash arrays
./search --print-url github 'bash arrays & loops'
./search --print-url --group Developer 'bash arrays'
./search --print-url --favorites 'terminal tools'
./search --browser firefox github 'bash arrays'
./search --no-color --help
./search --add-site stackoverflow 'Stack Overflow' so 'https://stackoverflow.com/search?q=' Developer
./search --remove-site so
```

`--print-url` shows the exact URL without opening a browser. `--group` opens the query on every site in that group; `--favorites` does the same for starred sites. Available groups include Web, Developer, Knowledge, Media, Community and Maps, plus any groups named in the user site file.

Run `s`, `S`, `search` or `Search` with no arguments in a terminal to open the interactive menu. The menu has category, destination and detail panels. Use **↑/↓** to move and **←/→** to choose the active panel. **Enter** opens the search prompt; **Esc** goes back or clears the active filter. Press **/** to enter filter mode and type a site name; **Enter** finishes filtering. Lowercase or uppercase **F** toggles the selected site's favorite status, **A** opens a form to add a site, and **D** removes the selected custom site after confirmation. Built-in sites cannot be removed. **Space** selects multiple sites, **G** cycles categories, **B** changes the browser, **C** changes the accent theme, **P** toggles private mode, and **Q** exits. Typing letters in the menu does not activate the filter unless filter mode is on. The selected category and destination stay highlighted while you move between panels.

From this source folder, use `./s`, `./S`, `./search` or `./Search` to run this checkout directly, even if an older system installation is earlier in `PATH`.

## User configuration

Configuration follows `XDG_CONFIG_HOME`, falling back to `~/.config`:

- Sites: `${XDG_CONFIG_HOME:-$HOME/.config}/universal-search/sites.conf`
- Favorites: `${XDG_CONFIG_HOME:-$HOME/.config}/universal-search/favorites`
- Settings: `${XDG_CONFIG_HOME:-$HOME/.config}/universal-search/settings.conf`

Copy `config/sites.conf.example` to the sites path. Add sites using:

```text
site|id|Display name|alias|URL prefix|Group
```

For example, `site|stackoverflow|Stack Overflow|so|https://stackoverflow.com/search?q=|Developer`. The query is URL-encoded and appended to the prefix. Existing four-column `id|label|alias|URL prefix` rows continue to work.

The interactive menu starts with Google, GitHub and YouTube as favorites. Press **F** or **f** to change a favorite; changes are saved in the favorites file. The settings file supports `browser=firefox` and `color=auto|always|never`. The **B** and **C** menu keys save settings. `UNIVERSAL_SEARCH_BROWSER` can override the configured browser for a shell session.

Add a custom site with `search --add-site ID NAME ALIAS URL_PREFIX [GROUP]`. The query is URL-encoded and appended to the URL prefix. Run `search --add-site` without arguments for guided prompts. The command adds one entry to `sites.conf` and keeps existing sites and settings intact.

Remove a custom site with `search --remove-site ID_OR_ALIAS` or select it in the menu and press **D**. The menu asks for confirmation. Removal deletes the site's entry and any matching favorite entry; built-in sites and unrelated configuration lines are kept.

History remains at `${XDG_DATA_HOME:-$HOME/.local/share}/universal-search/history`. The results directory is `${XDG_DATA_HOME:-$HOME/.local/share}/universal-search/results/`; this application opens search pages in the browser and does not download pages into that directory.

## Browser and private mode

Without a browser choice, normal searches use `xdg-open`. Private mode uses the selected or detected browser and its private-window flag: Firefox/LibreWolf/Floorp use `--private-window`, Chromium/Brave/Vivaldi use `--incognito`, Edge uses `--inprivate`, and Opera uses `--private`. The details panel shows whether a private-capable browser was detected. If none is available, press **B** to choose an installed browser or set `browser=NAME` in settings. For one command:

```bash
search --browser firefox github 'bash arrays'
```

## Install

For a local Bash installation:

```bash
sudo ./install.sh
```

This installs the program under `/usr/local/lib/universal-search/` and command links under `/usr/local/bin/`. It installs shell completions and a sample config under `/usr/local/share/`. `sudo ./uninstall.sh` removes application files and leaves user settings and data untouched.

Build a Debian package with `./build-deb.sh`, then install it with `sudo apt install ./dist/universal-search_1.0.8-1_all.deb`.

Build an Arch package with:

```bash
BUILDDIR="${TMPDIR:-/tmp}/universal-search-1.0.8-build" \
  PKGDEST="$PWD/dist" makepkg -Ccf --nodeps --skipinteg --nosign
```

Then install it with `sudo pacman -U dist/universal-search-1.0.8-1-any.pkg.tar.zst`.

## Tests

Run the Bash smoke tests with `./tests/run.sh`. They check URL encoding, custom sites and groups, favorites, and colorless help output without launching a browser.

## License

MIT. See [LICENSE](LICENSE).
