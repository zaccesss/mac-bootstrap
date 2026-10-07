#!/usr/bin/env bash
#
# Mac Bootstrap entry point. Runs every stage in order, then any extras asked for with --with.
# Safe to re-run: each stage checks what is already in place first. Written for the bash 3.2 that
# ships with macOS.

set -Eeuo pipefail

BOOTSTRAP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly BOOTSTRAP_ROOT
readonly STAGES_DIR="$BOOTSTRAP_ROOT/stages"

# shellcheck source=bootstrap/lib/logging.sh
source "$BOOTSTRAP_ROOT/lib/logging.sh"
# shellcheck source=bootstrap/lib/common.sh
source "$BOOTSTRAP_ROOT/lib/common.sh"
# shellcheck source=bootstrap/lib/platform.sh
source "$BOOTSTRAP_ROOT/lib/platform.sh"
# shellcheck source=bootstrap/lib/xcode.sh
source "$BOOTSTRAP_ROOT/lib/xcode.sh"
# shellcheck source=bootstrap/lib/configs.sh
source "$BOOTSTRAP_ROOT/lib/configs.sh"
# shellcheck source=bootstrap/lib/homebrew.sh
source "$BOOTSTRAP_ROOT/lib/homebrew.sh"
# shellcheck source=bootstrap/lib/dotfiles.sh
source "$BOOTSTRAP_ROOT/lib/dotfiles.sh"
# shellcheck source=bootstrap/lib/toolchains.sh
source "$BOOTSTRAP_ROOT/lib/toolchains.sh"
# shellcheck source=bootstrap/lib/settings.sh
source "$BOOTSTRAP_ROOT/lib/settings.sh"
# shellcheck source=bootstrap/lib/optional.sh
source "$BOOTSTRAP_ROOT/lib/optional.sh"

trap 'handle_error "$LINENO" "$BASH_COMMAND" "$?"' ERR

usage() {
    cat <<'EOF'
Usage: bootstrap.sh [options]

Sets up a Mac for development: Xcode tools, Homebrew and the Brewfile, the dotfiles, toolchains
and the captured macOS settings.

Options:
  --with a,b         also install these optional extras (see --list)
  --extras-only      skip the stages and install only the --with extras
  --settings-only    only apply the captured macOS settings
  --capture-settings record this Mac's settings into the defaults repository and exit
  --list             list the optional extras and exit
  -h, --help         show this help and exit
EOF
}

OPTIONAL_REQUESTED=()
MODE="full"

parse_arguments() {
    local names
    while (( $# > 0 )); do
        case "$1" in
            --with)
                [[ -n "${2:-}" ]] || { log_error "--with needs a comma-separated list of extras"; return 1; }
                IFS=',' read -r -a names <<< "$2"
                OPTIONAL_REQUESTED+=("${names[@]}")
                shift 2
                ;;
            --extras-only) MODE="extras"; shift ;;
            --settings-only) MODE="settings"; shift ;;
            --capture-settings) MODE="capture"; shift ;;
            --list) list_optional_tools; exit 0 ;;
            -h|--help) usage; exit 0 ;;
            *) log_error "Unknown option: $1"; usage >&2; return 1 ;;
        esac
    done

    if [[ "$MODE" == "extras" ]] && (( ${#OPTIONAL_REQUESTED[@]} == 0 )); then
        log_error "--extras-only needs --with to say which extras to install"
        return 1
    fi

    if (( ${#OPTIONAL_REQUESTED[@]} > 0 )); then
        validate_optional_tools "${OPTIONAL_REQUESTED[@]}"
    fi
}

main() {
    parse_arguments "$@"
    require_supported_platform

    case "$MODE" in
        capture) capture_settings; return 0 ;;
        settings) apply_settings; return 0 ;;
    esac

    log_info "Starting Mac Bootstrap"
    initialise_bootstrap

    if [[ "$MODE" == "full" ]]; then
        run_stage "xcode-tools" "$STAGES_DIR/00-xcode-tools.sh"
        run_stage "homebrew" "$STAGES_DIR/10-homebrew.sh"
        run_stage "dotfiles" "$STAGES_DIR/20-dotfiles.sh"
        run_stage "configs" "$STAGES_DIR/25-configs.sh"
        run_stage "brewfile" "$STAGES_DIR/30-brewfile.sh"
        run_stage "toolchains" "$STAGES_DIR/40-toolchains.sh"
        run_stage "settings" "$STAGES_DIR/50-settings.sh"
    fi

    if (( ${#OPTIONAL_REQUESTED[@]} > 0 )); then
        install_optional_tools "${OPTIONAL_REQUESTED[@]}"
    fi

    log_success "Mac Bootstrap completed"
    log_info "Open a new terminal so the shell profile loads"
}

main "$@"
