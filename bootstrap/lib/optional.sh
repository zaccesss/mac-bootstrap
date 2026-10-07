#!/usr/bin/env bash
#
# opt-in extras, chosen with --with name,name and listed with --list. Each entry is
# "name|description"

readonly OPTIONAL_TOOLS=(
    "vscode-extensions|VS Code extensions from the editor config repository"
    "linux|An OrbStack Ubuntu 26.04 machine set up with linux-bootstrap and its configs extra"
)

readonly LINUX_MACHINE="${MAC_BOOTSTRAP_LINUX_MACHINE:-ubuntu}"

optional_name() {
    printf '%s\n' "${1%%|*}"
}

list_optional_tools() {
    local entry

    printf 'Optional extras (install with --with name,name):\n\n'
    for entry in "${OPTIONAL_TOOLS[@]}"
    do
        printf '  %-18s %s\n' "$(optional_name "$entry")" "${entry#*|}"
    done
}

validate_optional_tools() {
    local name entry found

    for name in "$@"
    do
        found=0
        for entry in "${OPTIONAL_TOOLS[@]}"
        do
            [[ "$(optional_name "$entry")" == "$name" ]] && found=1
        done
        if (( ! found )); then
            log_error "Unknown optional extra: ${name}. Run with --list to see them all"
            return 1
        fi
    done
}

optional_vscode_extensions() {
    local list="${REPOS_DIR}/vscode-config/extensions.txt"

    clone_repository vscode-config "${REPOS_DIR}/vscode-config"

    if ! command -v code >/dev/null 2>&1; then
        log_warn "The code command is not on PATH; open VS Code and run 'Shell Command: Install code command in PATH', then run this extra again"
        return 0
    fi

    # the list pins versions (name@1.2.3) for the record, but only missing extensions are
    # installed and always at their latest version: installing the pinned one would roll an
    # up-to-date extension back
    local installed extension name
    installed="$(code --list-extensions | tr '[:upper:]' '[:lower:]')"
    while read -r extension; do
        [[ -z "$extension" || "$extension" == //* || "$extension" == \#* ]] && continue
        name="$(printf '%s' "${extension%%@*}" | tr '[:upper:]' '[:lower:]')"
        if ! grep -qx "$name" <<< "$installed"; then
            code --install-extension "$name" >/dev/null && log_info "Installed $name"
        fi
    done < "$list"
}

# the machine shares the Mac's home folder, so it runs linux-bootstrap straight from the Mac's
# clone; its configs extra then sets up the Linux shell profile and tool configs
optional_linux() {
    if ! command -v orb >/dev/null 2>&1; then
        log_error "OrbStack is not installed; it comes from the Brewfile"
        return 1
    fi

    orb start >/dev/null
    if ! orb list | grep -q "^${LINUX_MACHINE} "; then
        orb create ubuntu:resolute "$LINUX_MACHINE"
    fi

    clone_repository linux-bootstrap "${REPOS_DIR}/linux-bootstrap"

    orb run -m "$LINUX_MACHINE" bash -c "
        set -e
        BOOTSTRAP_GITHUB_USER='${GITHUB_USER}' '${REPOS_DIR}/linux-bootstrap/bootstrap/bootstrap.sh' --with configs
    "
    log_info "Open it with 'orb -m ${LINUX_MACHINE}' or the OrbStack Terminal tab"
}

install_optional_tools() {
    local name

    for name in "$@"
    do
        log_info "Installing optional extra: ${name}"
        "optional_${name//-/_}"
        log_success "Optional extra installed: ${name}"
    done
}
