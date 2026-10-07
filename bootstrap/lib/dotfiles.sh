#!/usr/bin/env bash
#
# GitHub sign-in, the dotfiles and the loader that makes the shell profile and prompt live. The
# profile is loaded from the clone rather than copied, so editing a topic file in the repo takes
# effect in the next terminal

sign_in_to_github() {
    if gh auth status >/dev/null 2>&1; then
        log_info "Already signed in to GitHub"
        return 0
    fi

    log_info "Signing in to GitHub; a browser window will ask you to confirm"
    gh auth login --hostname github.com --git-protocol https --web
    gh auth setup-git
}

# ~/.zshrc becomes a two-line loader: the dotfiles find their topic files through DOTFILES, so the
# clone can live anywhere. An existing ~/.zshrc moves into the backups folder first
write_zshrc_loader() {
    local loader
    loader="export DOTFILES=\"${DOTFILES_DIR}\"
source \"\${DOTFILES}/mac/zshrc\""

    if [[ -f "${HOME}/.zshrc" && ! -L "${HOME}/.zshrc" ]] && [[ "$(cat "${HOME}/.zshrc")" == "$loader" ]]; then
        log_info "Already loading the dotfiles: ${HOME}/.zshrc"
        return 0
    fi
    if [[ -e "${HOME}/.zshrc" || -L "${HOME}/.zshrc" ]]; then
        mkdir -p "$BACKUP_DIR"
        mv "${HOME}/.zshrc" "${BACKUP_DIR}/.zshrc-$(date +%Y%m%d-%H%M%S)"
        log_warn "Moved the existing ~/.zshrc into ${BACKUP_DIR}"
    fi
    printf '%s\n' "$loader" > "${HOME}/.zshrc"
    log_success "Wrote ~/.zshrc to load the dotfiles from ${DOTFILES_DIR}"
}

install_dotfiles() {
    clone_repository dotfiles "$DOTFILES_DIR"

    write_zshrc_loader
    link_file "${DOTFILES_DIR}/mac/starship.toml" "${HOME}/.config/starship.toml"
}
