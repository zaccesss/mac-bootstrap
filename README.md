# Mac Bootstrap

[![Bootstrap](https://github.com/zaccesss/mac-bootstrap/actions/workflows/bootstrap.yml/badge.svg)](https://github.com/zaccesss/mac-bootstrap/actions/workflows/bootstrap.yml)
[![Lint markdown files](https://github.com/zaccesss/mac-bootstrap/actions/workflows/markdownlint.yml/badge.svg)](https://github.com/zaccesss/mac-bootstrap/actions/workflows/markdownlint.yml)
[![License: Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)

One command that turns a new Mac into a complete development machine and keeps an existing one in
line. It covers the Xcode command line tools, Homebrew with every app and tool in the Brewfile, the
shell profile and prompt, the developer toolchains and the Mac's own settings.

## Quickstart

> [!WARNING]
> The bootstrap installs apps and changes macOS settings. Read [docs/how-it-works.md](docs/how-it-works.md)
> first so you know what each stage does.

On a brand-new Mac, open Terminal and run:

```bash
xcode-select --install          # click Install, wait for it to finish
git clone https://github.com/zaccesss/mac-bootstrap.git
./mac-bootstrap/bootstrap/bootstrap.sh
```

On a Mac that is already set up, running it again takes a few seconds, changes nothing and does not
ask for a password. It only acts where something is missing.

## What it does

| Stage | What happens |
| --- | --- |
| Xcode tools | Installs the command line tools (git, clang, make, the macOS SDK) if missing |
| Homebrew | Installs Homebrew if missing, plus the GitHub CLI |
| Dotfiles | Signs in to GitHub, clones the dotfiles and points the shell profile and prompt at them |
| Configs | Clones the config repositories (tmux, Neovim, Git hooks, VS Code settings, lazygit, ripgrep and fzf) and links each into place, copies starting Git and SSH configs, then gives Terminal.app and iTerm2 the High Contrast palette |
| Brewfile | Installs everything in the dotfiles' Brewfile without upgrading what is already there |
| Toolchains | Selects Rust's stable toolchain and checks every everyday tool is on `PATH` |
| Settings | Applies the macOS settings captured in the system defaults repository, writing only the ones that differ |

Extras, chosen with `--with`:

| Extra | What it installs |
| --- | --- |
| `vscode-extensions` | Any VS Code extension in the editor config repository that is missing, at its latest version |
| `linux` | An OrbStack Ubuntu machine set up with linux-bootstrap and its configs extra |

```bash
./bootstrap/bootstrap.sh --with vscode-extensions,linux
./bootstrap/bootstrap.sh --extras-only --with linux     # just the extra
./bootstrap/bootstrap.sh --settings-only                # just the settings
./bootstrap/bootstrap.sh --capture-settings             # record this Mac's settings in the defaults repository
```

## Your own configuration

The dotfiles and configs come from these public repositories:

| Repository | What it provides |
| --- | --- |
| [dotfiles](https://github.com/zaccesss/dotfiles) | zsh profile with aliases and helpers, the starship prompt and the Brewfile |
| [tmux-config](https://github.com/zaccesss/tmux-config) | tmux with vi-style copy mode |
| [neovim-config](https://github.com/zaccesss/neovim-config) | Neovim with LSP, treesitter and Telescope |
| [git-config](https://github.com/zaccesss/git-config) | A starting `~/.gitconfig` with SSH commit signing |
| [git-hooks](https://github.com/zaccesss/git-hooks) | Secret scanning, large file and force push guards |
| [ssh-config](https://github.com/zaccesss/ssh-config) | A starting `~/.ssh/config` |
| [cli-tools-config](https://github.com/zaccesss/cli-tools-config) | ripgrep, fzf and lazygit defaults |
| [vscode-config](https://github.com/zaccesss/vscode-config) | VS Code settings, keybindings and extensions |
| [terminal-config](https://github.com/zaccesss/terminal-config) | The High Contrast light and dark palette for Terminal.app and iTerm2 |
| [system-defaults](https://github.com/zaccesss/system-defaults) | macOS settings, captured and applied |

They are cloned into `~/.dotfiles` (change it with `BOOTSTRAP_CONFIG_DIR`) and linked into place,
so editing a file in a repository applies straight away. `~/.gitconfig` and `~/.ssh/config` are
copied once as a starting point instead, because they hold your own name, email, keys and hosts.
Fork the repositories and point the bootstrap at your own account to make them yours:

```bash
BOOTSTRAP_GITHUB_USER=<your GitHub user> ./mac-bootstrap/bootstrap/bootstrap.sh
```

## Documentation

| Page | What it covers |
| --- | --- |
| [How it works](docs/how-it-works.md) | Each stage in detail, what is never touched and where the lists live |
| [Settings](docs/settings.md) | Where the settings live and how they are captured and applied |
| [New Mac checklist](docs/new-mac.md) | Everything to do on a new Mac, including what the bootstrap cannot do |

## Other platforms

| Platform | Repository |
| --- | --- |
| macOS | [mac-bootstrap](https://github.com/zaccesss/mac-bootstrap) |
| Ubuntu, including WSL2 and VMs | [linux-bootstrap](https://github.com/zaccesss/linux-bootstrap) |
| Windows 11 | [windows-bootstrap](https://github.com/zaccesss/windows-bootstrap) |

All three use the same public dotfiles and config repositories.

## Development

Run the tests on any Mac with `/bin/bash tests/bootstrap-test.sh`. They use stubs for every command
that would change the Mac and run on the stock bash 3.2 that a new Mac has. Changes follow the
issue, branch, pull request, review and squash-merge workflow in [CONTRIBUTING.md](CONTRIBUTING.md).

> [!IMPORTANT]
> Do not commit passwords, API keys, private keys or tokens. See [SECURITY.md](SECURITY.md).

## Licence

Apache License, Version 2.0. See [LICENSE](LICENSE) and [NOTICE.md](NOTICE.md).

## Contact and Support

Open an [issue](https://github.com/zaccesss/mac-bootstrap/issues) for questions or bugs. See
[SUPPORT.md](SUPPORT.md) for where to go.

> [!TIP]
> Reach me directly at [contact@isaacadjei.me](mailto:contact@isaacadjei.me) or through the
> [website contact page](https://isaacadjei.me/contact).
