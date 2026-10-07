#!/usr/bin/env bash
#
# the Xcode command line tools: git, clang, make and the macOS SDK. Homebrew and almost every
# build need them, so they come first

# xcode-select --install opens Apple's own installer window and returns at once, so the stage
# waits for the tools to appear instead of racing ahead into Homebrew
install_xcode_tools() {
    if xcode-select -p >/dev/null 2>&1; then
        log_info "Xcode command line tools are already installed"
        return 0
    fi

    require_sudo
    log_info "Opening Apple's installer for the Xcode command line tools; click Install in the window that appears"
    xcode-select --install >/dev/null 2>&1 || true

    local waited=0
    until xcode-select -p >/dev/null 2>&1; do
        if (( waited >= 1800 )); then
            log_error "The Xcode command line tools did not finish installing within 30 minutes"
            return 1
        fi
        sleep 10
        waited=$((waited + 10))
    done

    log_success "Xcode command line tools installed"
}
