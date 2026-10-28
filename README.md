# Universal Search

**Universal Search** is an open-source Bash utility that lets you search multiple websites directly from the Linux terminal. It provides an interactive menu and a command-line mode with short website aliases.

## Features

- Interactive search menu.
- Command-line searching with short website aliases.
- Private/incognito browser mode with `-p` or `--private`.
- Command aliases: `s`, `S`, `search`, and `Search`.
- Universal Linux installer.
- Debian and Ubuntu package support.
- Arch Linux package support via `PKGBUILD`.
- Opens search results using `xdg-open`.

## Quick Start

### Requirements

- Bash
- `curl` or `wget`
- `sudo` or root privileges for system-wide installation
- `xdg-utils` to open links in a browser

### Install

Download and run the installer:

```bash
curl -fsSL https://raw.githubusercontent.com/fokompo/universal-search/main/install.sh -o install.sh
bash install.sh
```

Alternatively, clone the repository and run the installer locally:

```bash
git clone https://github.com/fokompo/universal-search.git
cd universal-search
bash install.sh
```

The installer uses the local `search` file if available; otherwise, it downloads the published version from GitHub.

## Usage

> **Version compatibility:** Available commands and options may differ between releases or installation methods. Run `s --help` or `search --help` to check the syntax supported by your installed version. If a command does not work, include your Linux distribution, installation method, package version, and help output when reporting the issue.

### Interactive Menu

Run any of these commands without arguments to open the interactive menu:

```bash
s
S
search
Search
```

### Command-Line Mode

Search a specific website directly from the terminal.

**Syntax:**

```bash
s [site] search terms
```

- `s` — runs Universal Search.
- `site` — the shortcut for the website you want to search.
- `search terms` — the words or phrase you want to find.

### Supported Websites and Shortcuts

Use these shortcuts instead of typing full website names.

| Shortcut | Website / Service |
|---|---|
| `google` | Google |
| `yt` | YouTube |
| `wiki` | Wikipedia |
| `gh` | GitHub |
| `reddit` | Reddit |
| `ddg` | DuckDuckGo |
| `mdn` | MDN Web Docs |
| `arch` | Arch Wikipedia |
| `maps` | Google Maps |
| `images` | Google Images |
| `bing` | Bing Search |
| `brave` | Brave Search |
| `npm` | npm Registry |
| `pypi` | Python Package Index |
| `rust` | Rust documentation |

The exact services and options available may depend on your installed version. Check the help output for the authoritative list.

### Search Examples

**Search YouTube:**

```bash
s yt linux tutorials
```

**Search GitHub:**

```bash
s gh bash scripts
```

**Search Wikipedia:**

```bash
s wiki Linux
```

**Search Google:**

```bash
s google best Linux distributions
s best Linux distributions
```

Replace the example text with your own search query.

### Private / Incognito Mode

Use `-p` or `--private` to request that search results open in a private or incognito browser window.

**Short option:**

```bash
s -p yt linux tutorials
```

**Long option:**

```bash
s --private google Linux commands
s --private Linux commands
s -p google Linux commands
s -p Linux commands
```

More examples:

```bash
s -p gh bash scripts
s --private wiki Linux
```

Private mode depends on your browser and system configuration. It does not make your internet activity completely anonymous.

### Open a Direct URL

You can also provide a URL directly:

```bash
s https://example.com
```

### Help

Display the available commands, options, and supported websites:

```bash
s --help
```

You can also use:

```bash
search --help
```

## Debian and Ubuntu

### Install a Local Debian Package

If you have downloaded a `.deb` package, install it with:

```bash
sudo apt install ./universal-search_VERSION_all.deb
```

Replace `VERSION` with the actual version in the package filename.

Alternatively:

```bash
sudo dpkg -i ./universal-search_VERSION_all.deb
```

### Build the Debian Package

Install the packaging tools:

```bash
sudo apt update
sudo apt install build-essential debhelper dpkg-dev
```

Then follow the package-building instructions in the repository.

## Arch Linux

The repository includes a `PKGBUILD` for Arch Linux and compatible distributions.

Follow the repository's packaging instructions and check the dependencies listed in `PKGBUILD` before building the package.

## Uninstall

If you installed Universal Search using the universal installer, run the uninstaller from the repository directory:

```bash
bash uninstall.sh
```

If you installed the Debian package:

```bash
sudo apt remove universal-search
```

For other installation methods, use the package manager or the removal instructions appropriate to your installation.

## Linux Compatibility

The universal installer does not require `apt`, `pacman`, or `dnf` just to install the program files.

It installs the program under:

- `/usr/local/lib/universal-search`
- `/usr/local/bin`

These directories are commonly available without manually changing `PATH`.

Universal Search uses `xdg-open` to open links. If it is missing, install `xdg-utils` using your distribution's package manager.

## Feedback and Contributions

Feedback, bug reports, and contributions are welcome.

- **Repository:** [Universal Search](https://github.com/fokompo/universal-search)
- **Report a bug:** [GitHub Issues](https://github.com/fokompo/universal-search/issues)

When reporting a problem, please include:

- Your Linux distribution.
- Your installation method (installer, Debian package, or Arch package).
- Your installed package version, if applicable.
- The command you ran and the resulting output.
- The output of `s --help`.

Testing on Ubuntu and other Linux distributions is especially useful for identifying compatibility issues.

## License

Universal Search is released under the MIT License. See the [LICENSE](https://github.com/fokompo/universal-search/blob/main/LICENSE) file.
