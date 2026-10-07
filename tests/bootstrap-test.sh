#!/usr/bin/env bash
#
# offline tests for the Mac bootstrap. brew, defaults, gh, git, xcode-select, code and orb are
# stubs that record their calls. `defaults` keeps its values in a small file, so the settings
# logic is exercised end to end without touching the Mac. Runs on the stock macOS bash 3.2.

set -Eeuo pipefail


REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly REPO_ROOT
readonly BOOTSTRAP="$REPO_ROOT/bootstrap/bootstrap.sh"
WORK_DIR="$(mktemp -d)"
readonly WORK_DIR
trap 'rm -rf "$WORK_DIR"' EXIT

TESTS_RUN=0
pass() { TESTS_RUN=$((TESTS_RUN + 1)); printf 'ok %d - %s\n' "$TESTS_RUN" "$1"; }
fail() { printf 'not ok - %s\n' "$1" >&2; exit 1; }
assert_contains() { [[ "$2" == *"$1"* ]] || fail "${3:-output} should contain: $1"; }
assert_not_contains() { [[ "$2" != *"$1"* ]] || fail "${3:-output} should not contain: $1"; }

STUBS="$WORK_DIR/bin"
HOME_DIR="$WORK_DIR/home"
CALLS="$WORK_DIR/calls.log"
DEFAULTS_DB="$WORK_DIR/defaults.db"
mkdir -p "$STUBS" "$HOME_DIR"

# every stub records "name args" so tests can see what would have run
make_stub() {
    printf '#!/bin/bash\nprintf "%%s %%s\\n" "%s" "$*" >> "%s"\n%s\n' "$1" "$CALLS" "${2:-exit 0}" > "$STUBS/$1"
    chmod +x "$STUBS/$1"
}

# brew bundle check reports missing apps (BREW_CHECK_EXIT=1) until an install has run
# shellcheck disable=SC2016  # the body expands when the stub runs, not here
make_stub brew 'case "$1" in bundle) case "$2" in check) [[ -f "'"$WORK_DIR"'/brew-installed" ]] || exit "${BREW_CHECK_EXIT:-0}";; install) touch "'"$WORK_DIR"'/brew-installed";; esac;; shellenv) echo "true";; esac; exit 0'
# shellcheck disable=SC2016
make_stub gh 'case "$1" in auth) [[ "$2" == status ]] && exit "${GH_AUTH_EXIT:-0}";; repo) mkdir -p "$4/.git";; esac; exit 0'
make_stub xcode-select 'exit 0'
make_stub killall 'exit 0'
make_stub sudo 'exit 0'
make_stub rustup 'exit 0'
make_stub scutil 'echo TestMac'

# defaults keeps "domain key type value" lines in a file; write can be told to refuse a domain
cat > "$STUBS/defaults" <<EOF
#!/bin/bash
db="$DEFAULTS_DB"
touch "\$db"
printf 'defaults %s\n' "\$*" >> "$CALLS"
case "\$1" in
    read-type)
        line=\$(grep -F "\$2|\$3|" "\$db" | tail -1) || exit 1
        [ -n "\$line" ] || exit 1
        echo "Type is \$(echo "\$line" | cut -d'|' -f3)" ;;
    read)
        line=\$(grep -F "\$2|\$3|" "\$db" | tail -1) || exit 1
        [ -n "\$line" ] || exit 1
        echo "\$line" | cut -d'|' -f4- ;;
    write)
        [ "\$2" = "\${DEFAULTS_REFUSE:-none}" ] && exit 1
        case "\$4" in -bool) t=boolean;; -int) t=integer;; -float) t=float;; *) t=string;; esac
        grep -v -F "\$2|\$3|" "\$db" > "\$db.tmp" || true
        mv "\$db.tmp" "\$db"
        echo "\$2|\$3|\$t|\$5" >> "\$db" ;;
esac
EOF
chmod +x "$STUBS/defaults"

# the commands the toolchain check looks for
# git clone makes the target folder look cloned, so nothing touches the network
# shellcheck disable=SC2016
make_stub git '[[ "$1" == clone ]] && mkdir -p "${@: -1}/.git"; exit 0'
for c in node npm python3 go java php starship zoxide fzf rg nvim lazygit delta uv ruff typst trivy lychee shellcheck pwsh; do
    make_stub "$c"
done


# the defaults repository script, which records how it was called
DEFAULTS_STUB="$WORK_DIR/defaults.sh"
printf '#!/bin/bash\nprintf "defaults-script %%s\\n" "$*" >> "%s"\n' "$CALLS" > "$DEFAULTS_STUB"
mkdir -p "$HOME_DIR/repos/system-defaults/.git"

run_bootstrap() {
    : > "$CALLS"
    PATH="$STUBS:/usr/bin:/bin" \
    HOME="$HOME_DIR" \
    MAC_BOOTSTRAP_TEST_MODE=1 \
    MAC_BOOTSTRAP_UNAME="${UNAME:-Darwin}" \
    MAC_BOOTSTRAP_MACOS_VERSION="${MACOS:-26.0}" \
    MAC_BOOTSTRAP_ARCH="${ARCH:-arm64}" \
    MAC_BOOTSTRAP_REPOS_DIR="$HOME_DIR/repos" \
    MAC_BOOTSTRAP_DEFAULTS_SCRIPT="$WORK_DIR/defaults.sh" \
    MAC_BOOTSTRAP_BREWFILE="$WORK_DIR/Brewfile" \
        "$BOOTSTRAP" "$@"
}
touch "$WORK_DIR/Brewfile"

# --- arguments and platform -----------------------------------------------------------------

assert_contains "--capture-settings" "$("$BOOTSTRAP" --help)" "--help"
pass "--help describes the options"

assert_contains "vscode-extensions" "$("$BOOTSTRAP" --list)" "--list"
pass "--list names the optional extras"

run_bootstrap --with nope >/dev/null 2>&1 && fail "an unknown extra should stop the run"
pass "an unknown extra stops the run"

UNAME=Linux run_bootstrap >/dev/null 2>&1 && fail "Linux should be refused"
pass "a non-Mac system is refused"

MACOS=13.6 run_bootstrap >/dev/null 2>&1 && fail "macOS 13 should be refused"
pass "macOS older than 14 is refused"

output="$(ARCH=x86_64 run_bootstrap --settings-only 2>&1)"
assert_contains "macOS 26.0 on x86_64" "$output"
pass "Intel Macs are accepted"

# --- settings come from the defaults repository ---------------------------------------------

run_bootstrap --settings-only >/dev/null
assert_contains "defaults-script " "$(cat "$CALLS")" "calls"
pass "--settings-only runs the defaults repository's script"

run_bootstrap --capture-settings >/dev/null
assert_contains "defaults-script --capture" "$(cat "$CALLS")" "calls"
pass "--capture-settings asks the defaults script to capture"

# --- the full run ---------------------------------------------------------------------------

mkdir -p "$HOME_DIR/repos/dotfiles/mac" "$HOME_DIR/repos/git-config/mac" "$HOME_DIR/repos/ssh-config/mac"
touch "$HOME_DIR/repos/dotfiles/mac/zshrc" "$HOME_DIR/repos/dotfiles/mac/starship.toml"
echo "[user]" > "$HOME_DIR/repos/git-config/mac/gitconfig"
echo "Host *" > "$HOME_DIR/repos/ssh-config/mac/config"
mkdir -p "$HOME_DIR/opt"
echo "# hand-written" > "$HOME_DIR/.zshrc"
# the platform check expects brew at the Homebrew prefix, so a fake prefix is not possible; the
# stub brew on PATH stands in and install_homebrew is told brew already exists
output="$(BREW_CHECK_EXIT=1 run_bootstrap 2>&1)" || true
calls="$(cat "$CALLS")"
for stage in xcode-tools homebrew dotfiles configs brewfile toolchains settings; do
    assert_contains "Completed stage: ${stage}" "$output"
done
assert_contains "brew bundle install" "$calls" "calls"
grep -q "source.*mac/zshrc" "$HOME_DIR/.zshrc" || fail "the zshrc loader was not written"
ls "$HOME_DIR"/.local/state/mac-bootstrap/backups/.zshrc-* >/dev/null 2>&1 || fail "the hand-written zshrc was not kept in the backups folder"
for link in .tmux.conf .config/nvim .git-hooks ".config/fzf/fzf.zsh" .ripgreprc "Library/Application Support/Code/User/settings.json"; do
    [[ -L "$HOME_DIR/$link" ]] || fail "$link was not linked to its config repository"
done
for copy in .gitconfig .ssh/config; do
    [[ -f "$HOME_DIR/$copy" && ! -L "$HOME_DIR/$copy" ]] || fail "$copy was not copied as a starting point"
done
pass "a full run completes every stage, links the config repositories, copies the personal templates and keeps a hand-written zshrc"

output="$(run_bootstrap 2>&1)"
calls="$(cat "$CALLS")"
assert_contains "Already linked" "$output"
assert_contains "already installed" "$output"
assert_not_contains "brew bundle install" "$calls" "calls"
assert_not_contains "sudo" "$calls" "calls"
pass "a second run changes nothing and never asks for the password"

printf '\nAll %d bootstrap tests passed.\n' "$TESTS_RUN"
