# How it works

`bootstrap/bootstrap.sh` checks the Mac, then runs six stages in order. Each stage looks first and
acts only where something is missing, so the same command sets up a new Mac and re-checks an old one.

## The stages

### 1. Xcode command line tools

Homebrew and almost every build need git, clang and the macOS SDK. If they are missing, Apple's own
installer window opens; click **Install**. The bootstrap waits for it to finish (up to 30 minutes).

### 2. Homebrew

Homebrew is installed if missing, under `/opt/homebrew` on Apple Silicon or `/usr/local` on Intel.
The GitHub CLI is installed straight away so the next stage can sign in.

### 3. Dotfiles

- signs in to GitHub with `gh auth login` in the browser, if not already signed in
- clones the dotfiles into `~/.dotfiles/dotfiles`
- writes `~/.zshrc` as a two-line loader for the profile in that clone and links
  `~/.config/starship.toml` to its prompt

Loading rather than copying means editing a topic file in the repository changes the next terminal.
An existing `~/.zshrc` is moved into `~/.local/state/mac-bootstrap/backups`, never deleted.

### 3b. Config repositories

Clones the config repositories into `~/.dotfiles` and links each file into place: `~/.tmux.conf`,
`~/.config/nvim`, `~/.git-hooks`, VS Code's `settings.json` and `keybindings.json`, lazygit's
`config.yml`, `~/.ripgreprc` and `~/.config/fzf/fzf.zsh`. `~/.gitconfig` and `~/.ssh/config` are
copied once if missing, since they hold your own identity. It then installs the tmux plugin manager
and runs terminal-config's installer for the High Contrast palette. Anything already there that is
not a link is moved into `~/.local/state/mac-bootstrap/backups` first.

### 4. Brewfile

Everything in the dotfiles' `mac/Brewfile` is installed: command-line tools, apps and fonts. Apps
already installed are left at their version; upgrades stay a deliberate `brew upgrade`. If
`brew bundle check` reports nothing missing, the stage finishes without touching anything.

The Brewfile lives in the dotfiles, not here, so there is one list of what a Mac should have. After
installing something new by hand, run `bdump` in the shell to add it to the Brewfile.

### 5. Toolchains

Selects Rust's stable toolchain (Homebrew installs rustup without one), then checks that every
everyday tool is on `PATH`, naming any that are missing.

### 6. Settings

Clones the system defaults repository and runs its macOS script, which applies the settings captured from
a set-up Mac. See [Settings](settings.md).

## When the password is asked for

Only when a step really needs administrator rights: installing the Xcode tools or Homebrew, plus
Brewfile apps that come as system packages. It is asked once and kept for the rest of the run. A Mac
that is already set up is never asked.

## What it never does

- remove apps, packages or files (a replaced `~/.zshrc` is kept as a backup)
- upgrade apps that are already installed
- create SSH keys or change Git identity, which the dotfiles and the SSH config repository own
- change a setting that is not in the captured list

## Where things live

| What | Where |
| --- | --- |
| The bootstrap and its stages | `bootstrap/` in this repository |
| Captured settings and the tracked key list | `mac/` in system-defaults |
| Apps and tools | `mac/Brewfile` in the dotfiles |
| Shell profile and prompt | `mac/zshrc`, `mac/topics/` and `mac/starship.toml` in the dotfiles |
| VS Code extensions | `extensions.txt` in vscode-config |
| Progress log | `~/.local/state/mac-bootstrap/stages.log` |
