#!/usr/bin/env bash
#
# toolchains that Homebrew installs but does not finish setting up, then a check that the tools
# used every day are really on PATH

# rustup is installed by the Brewfile with no toolchain selected, so cargo and rustc do nothing
# until one is chosen
set_up_rust() {
    if ! command -v rustup >/dev/null 2>&1; then
        log_warn "rustup is not installed; skipping the Rust toolchain"
        return 0
    fi

    rustup default stable
}

# commands the final check expects on PATH. They all come from the Brewfile, so a missing one
# means the Brewfile and this list have drifted apart
readonly TOOLCHAIN_COMMANDS=(
    git
    gh
    node
    npm
    python3
    go
    rustup
    java
    php
    starship
    zoxide
    fzf
    rg
    nvim
    lazygit
    delta
    uv
    ruff
    typst
    trivy
    lychee
    shellcheck
    pwsh
)

verify_toolchains() {
    verify_commands "Toolchain" "${TOOLCHAIN_COMMANDS[@]}"
}

set_up_toolchains() {
    set_up_rust
    verify_toolchains
}
