# Universal Search

Universal Search — terminal search with a colorful interactive menu and CLI mode.

## Features

- Interactive menu.
- CLI mode when arguments are supplied.
- Commands: `s`, `S`, `search`, `Search`.
- Universal installer for Linux.
- Debian package support.
- Arch Linux package support through `PKGBUILD`.

## Universal installation

Requirements: Bash, `curl` or `wget`, and `sudo` or root access.

```bash
curl -fsSL https://raw.githubusercontent.com/fokompo/universal-search/main/install.sh -o install.sh
bash install.sh
```

Or install from a cloned repository:

```bash
git clone https://github.com/fokompo/universal-search.git
cd universal-search
bash install.sh
```

The installer uses the local `search` file if present; otherwise it downloads
the published version from GitHub.

## Commands

All four commands open the interactive menu without arguments:

```bash
s
S
search
Search
```

When arguments are supplied, they are passed to CLI mode. For help, run:

```bash
search --help
```

## Debian package

On a Debian-based system, install a built package with:

```bash
sudo apt install ./universal-search_1.0.0-1_all.deb
```

Or:

```bash
sudo dpkg -i ./universal-search_1.0.0-1_all.deb
```

To build the package on Debian or Ubuntu, install the packaging tools and run:

```bash
sudo apt install build-essential debhelper
dpkg-buildpackage -us -uc -b
```

## Arch Linux

The repository includes a `PKGBUILD` for Arch-based distributions.

## Uninstallation

For the universal installer, run the repository's `uninstall.sh`:

```bash
bash uninstall.sh
```

For a Debian package:

```bash
sudo apt remove universal-search
```

## Linux compatibility

The universal installer does not require `apt`, `pacman`, or `dnf`.
It installs into `/usr/local/lib/universal-search` and `/usr/local/bin`.
Those directories are normally available without manually editing `PATH`.

The program uses `xdg-open` to open links. Install `xdg-utils` through
your distribution's package manager if it is not already available.

## License

MIT. See [LICENSE](LICENSE).
