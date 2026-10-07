#!/usr/bin/env bash
#
# the config repositories, each cloned once and linked into place so an edit in the repository
# applies straight away. Files that hold a person's own name, email, keys and hosts are copied once
# as a starting point instead and never overwritten

# "repository|path inside the repository|where it is linked"
readonly CONFIG_LINKS=(
    "tmux-config|tmux.conf|${HOME}/.tmux.conf"
    "neovim-config|nvim|${HOME}/.config/nvim"
    "git-hooks|mac|${HOME}/.git-hooks"
    "vscode-config|settings.json|${HOME}/Library/Application Support/Code/User/settings.json"
    "vscode-config|keybindings/mac.json|${HOME}/Library/Application Support/Code/User/keybindings.json"
    "cli-tools-config|lazygit/config.yml|${HOME}/Library/Application Support/lazygit/config.yml"
    "cli-tools-config|ripgrep/ripgreprc|${HOME}/.ripgreprc"
    "cli-tools-config|fzf/fzf.zsh|${HOME}/.config/fzf/fzf.zsh"
)

# "repository|path inside the repository|where it is copied"
readonly CONFIG_TEMPLATES=(
    "git-config|mac/gitconfig|${HOME}/.gitconfig"
    "ssh-config|mac/config|${HOME}/.ssh/config"
)

install_config_repos() {
    local entry repository inside target

    for entry in "${CONFIG_LINKS[@]}"
    do
        IFS='|' read -r repository inside target <<< "$entry"
        clone_repository "$repository" "${REPOS_DIR}/${repository}"
        link_file "${REPOS_DIR}/${repository}/${inside}" "$target"
    done

    for entry in "${CONFIG_TEMPLATES[@]}"
    do
        IFS='|' read -r repository inside target <<< "$entry"
        if [[ -e "$target" ]]; then
            log_info "Keeping your existing ${target}"
            continue
        fi
        clone_repository "$repository" "${REPOS_DIR}/${repository}"
        mkdir -p "$(dirname "$target")"
        cp "${REPOS_DIR}/${repository}/${inside}" "$target"
        log_warn "Copied a starting ${target}; edit it for your own name, email, keys and hosts"
    done
    chmod 700 "${HOME}/.ssh" 2>/dev/null || true

    # tmux's plugins come from its own plugin manager, which the config expects in this folder
    if [[ ! -d "${HOME}/.tmux/plugins/tpm" ]] && ! is_test_mode; then
        git clone --depth 1 https://github.com/tmux-plugins/tpm "${HOME}/.tmux/plugins/tpm"
        "${HOME}/.tmux/plugins/tpm/bin/install_plugins" >/dev/null
    fi

    # Terminal.app and iTerm2 keep their profiles in their own preference files, so the terminal
    # repository's installer applies the High Contrast palette rather than a plain link
    clone_repository terminal-config "${REPOS_DIR}/terminal-config"
    if ! is_test_mode; then
        bash "${REPOS_DIR}/terminal-config/mac/install.sh"
    fi
}
