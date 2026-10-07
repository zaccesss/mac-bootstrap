#!/usr/bin/env bash
#
# checks the Mac before any stage runs and records what later stages need: the chip (which
# decides where Homebrew lives) and the macOS version
#
# exported values:
#   MAC_ARCH          arm64 (Apple Silicon) or x86_64 (Intel)
#   MAC_VERSION       the macOS version, for example 26.0
#   HOMEBREW_PREFIX   /opt/homebrew on Apple Silicon, /usr/local on Intel

# Homebrew supports the three most recent major macOS releases; older ones get bottles late or
# not at all, so the bootstrap stops rather than spend an hour compiling from source
readonly MINIMUM_MACOS_MAJOR=14

require_supported_platform() {
    local system
    system="${MAC_BOOTSTRAP_UNAME:-$(uname -s)}"

    if [[ "$system" != "Darwin" ]]; then
        log_error "This bootstrap is for macOS; found ${system}. Use .linux-bootstrap on Linux"
        return 1
    fi

    MAC_VERSION="${MAC_BOOTSTRAP_MACOS_VERSION:-$(sw_vers -productVersion)}"
    MAC_ARCH="${MAC_BOOTSTRAP_ARCH:-$(uname -m)}"

    local major="${MAC_VERSION%%.*}"
    if (( major < MINIMUM_MACOS_MAJOR )); then
        log_error "macOS ${MAC_VERSION} is too old; ${MINIMUM_MACOS_MAJOR} (Sonoma) or later is needed"
        return 1
    fi

    case "$MAC_ARCH" in
        arm64) HOMEBREW_PREFIX="/opt/homebrew" ;;
        x86_64) HOMEBREW_PREFIX="/usr/local" ;;
        *)
            log_error "Unsupported processor: ${MAC_ARCH}"
            return 1
            ;;
    esac

    export MAC_ARCH MAC_VERSION HOMEBREW_PREFIX
    log_success "Platform detected: macOS ${MAC_VERSION} on ${MAC_ARCH}"
}
