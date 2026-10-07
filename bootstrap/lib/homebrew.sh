#!/usr/bin/env bash
#
# Homebrew and everything in the Brewfile. The Brewfile lives in the dotfiles, not here, so there
# is one list of what a Mac should have and `bdump` in the shell profile keeps it current

readonly BREWFILE="${MAC_BOOTSTRAP_BREWFILE:-${DOTFILES_DIR}/mac/Brewfile}"

install_homebrew() {
    local brew_bin="${HOMEBREW_PREFIX}/bin/brew"
    # the test suite's stub brew stands in for the real one, which would otherwise put the Mac's
    # real tools ahead of the stubs on PATH
    if is_test_mode; then
        brew_bin="$(command -v brew)"
    fi

    if [[ -x "$brew_bin" ]]; then
        log_info "Homebrew is already installed"
    else
        log_info "Installing Homebrew"
        require_sudo
        local installer
        installer="$(mktemp)"
        curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh -o "$installer"
        # NONINTERACTIVE skips Homebrew's "press RETURN" prompt; require_sudo has the password
        NONINTERACTIVE=1 /bin/bash "$installer"
        rm -f "$installer"
    fi

    # puts brew and everything it installs on PATH for the rest of this run; the shell profile
    # does the same for every new terminal
    eval "$("$brew_bin" shellenv)"
}

# the GitHub CLI is needed before anything else so the private dotfiles can be cloned
install_github_cli() {
    if command -v gh >/dev/null 2>&1; then
        return 0
    fi

    brew install gh
}

install_brewfile() {
    if [[ ! -f "$BREWFILE" ]]; then
        log_error "Brewfile not found: $BREWFILE"
        return 1
    fi

    if brew bundle check --file="$BREWFILE" --no-upgrade >/dev/null 2>&1; then
        log_success "Everything in the Brewfile is already installed"
        return 0
    fi

    # some apps install through a package that needs the administrator password
    require_sudo
    log_info "Installing everything in $BREWFILE"
    # --no-upgrade leaves already-installed apps at their current version; upgrades stay a
    # deliberate `brew upgrade` rather than a side effect of re-running the bootstrap
    brew bundle install --file="$BREWFILE" --no-upgrade

    brew bundle check --file="$BREWFILE" --no-upgrade
    log_success "Everything in the Brewfile is installed"
}
