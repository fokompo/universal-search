# Universal Search

**Universal Search** is an open-source Bash utility for searching multiple websites directly from the terminal. It features a colorful interactive menu and a command-line mode.

## Features

- Colorful interactive search menu.
- Command-line mode when arguments are provided.
- Command aliases: `s`, `S`, `search`, and `Search`.
- Universal installer for Linux.
- Debian package support.
- Arch Linux package support via `PKGBUILD`.
- Opens search results using `xdg-open`.

## Quick Start

### Requirements

- Bash
- `curl` or `wget`
- `sudo` or root privileges for system-wide installation
- `xdg-utils` for opening links

### Install

Download and run the installer:

```bash
curl -fsSL https://raw.githubusercontent.com/fokompo/universal-search/main/install.sh -o install.sh
bash install.sh
```

Or clone the repository and run the installer locally:

```bash
git clone https://github.com/fokompo/universal-search.git
cd universal-search
bash install.sh
```

The installer uses the local `search` file if available; otherwise, it downloads the published version from GitHub.

## Usage

### Interactive Menu

Run any of these commands without arguments to open the interactive menu:

```bash
s
S
search
Search
```

### Command-Line Mode

When arguments are provided, they are passed to command-line mode.

For example, to search YouTube:

```bash
S yt text
```

To use the `-p` option:

```bash
S yt -p text
```

Replace `text` with your search query. The exact behavior of options depends on the command syntax supported by your installed version.

### Help

Display available commands, options, and supported websites:

```bash
search --help
```

## Debian and Ubuntu

### Install a Local Debian Package

If you have downloaded a `.deb` package, install it with:

```bash
sudo apt install ./universal-search_VERSION_all.deb
```

Alternatively:

```bash
sudo dpkg -i ./universal-search_VERSION_all.deb
```

Replace `VERSION` with the actual version in the downloaded filename.

### Build the Debian Package

On Debian or Ubuntu, install the packaging tools:

```bash
sudo apt update
sudo apt install build-essential debhelper dpkg-dev
```

Then follow the package-building instructions in the repository.

## Arch Linux

The repository includes a `PKGBUILD` for Arch Linux and compatible distributions.

To build and install the package, follow the Arch packaging instructions and review the dependencies listed in `PKGBUILD`.

## Uninstall

If you installed Universal Search using the universal installer, run the uninstaller from the repository directory:

```bash
bash uninstall.sh
```

If you installed the Debian package:

```bash
sudo apt remove universal-search
```

For other installation methods, use the package manager or removal instructions corresponding to your installation.

## Linux Compatibility

The universal installer does not require `apt`, `pacman`, or `dnf` to be present just to install files. It installs the program under:

- `/usr/local/lib/universal-search`
- `/usr/local/bin`

These directories are commonly available without manually changing `PATH`.

Universal Search uses `xdg-open` to open links. If it is missing, install `xdg-utils` using your distribution's package manager.

## Feedback and Contributions

Feedback, bug reports, and suggestions are welcome.

- **Repository:** https://github.com/fokompo/universal-search
- **Issues:** https://github.com/fokompo/universal-search/issues

If you test Universal Search on Ubuntu or another Linux distribution, please share your experience and report any compatibility problems.

## License

Universal Search is released under the MIT License. See [LICENSE](https://github.com/fokompo/universal-search/blob/main/LICENSE).
