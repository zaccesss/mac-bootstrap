#!/usr/bin/env bash
#
# shared plumbing for every stage. Written for the bash 3.2 that ships with macOS, because a new
# Mac has no other bash until Homebrew installs one: no associative arrays, no mapfile and no
# ${var,,} case changes anywhere in this repository.
#
# run modes:
#   normal   changes the Mac for real
#   test     MAC_BOOTSTRAP_TEST_MODE=1. brew, defaults, gh, git and the other commands are stubs
#            from the test suite, so nothing touches the network or the machine

readonly BOOTSTRAP_STATE_DIR="${HOME}/.local/state/mac-bootstrap"
# the dotfiles and config repositories are cloned here. They default to the public ones this
# project was built alongside; point BOOTSTRAP_GITHUB_USER at your own account to use your forks
readonly REPOS_DIR="${BOOTSTRAP_CONFIG_DIR:-${MAC_BOOTSTRAP_REPOS_DIR:-${HOME}/.dotfiles}}"
readonly GITHUB_USER="${BOOTSTRAP_GITHUB_USER:-zaccesss}"
# shellcheck disable=SC2034  # used by dotfiles.sh, homebrew.sh and optional.sh
readonly DOTFILES_DIR="${REPOS_DIR}/dotfiles"

is_test_mode() {
    [[ "${MAC_BOOTSTRAP_TEST_MODE:-0}" == "1" ]]
}

initialise_bootstrap() {
    mkdir -p "$BOOTSTRAP_STATE_DIR"
    log_info "Bootstrap state directory: $BOOTSTRAP_STATE_DIR"
}

# asks for the administrator password, once, the first time a step really needs it, then keeps
# the timestamp fresh so a long install never stops at a second prompt. A re-run on a Mac that is
# already set up never asks at all
SUDO_READY=0
require_sudo() {
    if (( SUDO_READY )); then
        return 0
    fi
    SUDO_READY=1

    if is_test_mode || sudo -n true 2>/dev/null; then
        return 0
    fi

    log_info "Administrator access is needed for Homebrew and the Xcode command line tools"
    sudo -v

    local parent_pid="$$"
    (
        while kill -0 "$parent_pid" 2>/dev/null; do
            sudo -n true 2>/dev/null
            sleep 50
        done
    ) &
}

# clones one of GITHUB_USER's public repositories unless it is already there, so a re-run never
# touches work in progress. Plain git over HTTPS, so no GitHub sign-in is needed
clone_repository() {
    local repository="$1"
    local target="$2"

    if [[ -d "$target/.git" ]]; then
        log_info "Already cloned: $target"
        return 0
    fi

    mkdir -p "$(dirname "$target")"
    git clone "https://github.com/${GITHUB_USER}/${repository}.git" "$target"
}

# links a file or folder into place. An existing real one is moved into the state folder's backups
# with a timestamp rather than overwritten, so nothing written by hand is ever lost and the home
# folder does not fill up with backup copies
readonly BACKUP_DIR="${BOOTSTRAP_STATE_DIR}/backups"

link_file() {
    local source="$1"
    local target="$2"

    if [[ -L "$target" && "$(readlink "$target")" == "$source" ]]; then
        log_info "Already linked: $target"
        return 0
    fi

    if [[ -e "$target" && ! -L "$target" ]]; then
        local backup
        mkdir -p "$BACKUP_DIR"
        backup="${BACKUP_DIR}/$(basename "$target")-$(date +%Y%m%d-%H%M%S)"
        mv "$target" "$backup"
        log_warn "Moved the existing $target to $backup"
    fi

    mkdir -p "$(dirname "$target")"
    ln -sfn "$source" "$target"
    log_success "Linked $target"
}

# checks that every command given is on PATH and names each missing one before failing
verify_commands() {
    local label="$1"
    shift
    local command_name
    local missing=0

    for command_name in "$@"
    do
        if ! command -v "$command_name" >/dev/null 2>&1; then
            log_error "${label} command is unavailable: ${command_name}"
            missing=1
        fi
    done

    if (( missing )); then
        return 1
    fi

    log_success "${label} verified successfully"
}

run_stage() {
    local stage_name="$1"
    local stage_path="$2"

    if [[ ! -x "$stage_path" ]]; then
        log_error "Stage is missing or not executable: $stage_path"
        return 1
    fi

    log_info "Running stage: $stage_name"
    # shellcheck disable=SC1090
    source "$stage_path"
    printf '%s %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$stage_name" >> "${BOOTSTRAP_STATE_DIR}/stages.log"
    log_success "Completed stage: $stage_name"
}
