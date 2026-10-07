#!/usr/bin/env bash
#
# macOS settings live in the defaults repository, which holds the tracked key list, the values
# captured from a real Mac and the script that captures and applies them. Keeping both there means
# one source of truth for every machine's settings

readonly DEFAULTS_DIR="${REPOS_DIR}/system-defaults"
readonly DEFAULTS_SCRIPT="${MAC_BOOTSTRAP_DEFAULTS_SCRIPT:-${DEFAULTS_DIR}/mac/defaults.sh}"

apply_settings() {
    clone_repository system-defaults "$DEFAULTS_DIR"
    /bin/bash "$DEFAULTS_SCRIPT"
}

capture_settings() {
    clone_repository system-defaults "$DEFAULTS_DIR"
    /bin/bash "$DEFAULTS_SCRIPT" --capture
    log_info "Commit the updated mac/defaults.tsv in ${DEFAULTS_DIR}, in your own fork"
}
