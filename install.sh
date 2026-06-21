#!/usr/bin/env bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════
# Dotfiles Installer
# ═══════════════════════════════════════════════════════════════

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST="$DOTFILES_DIR/config/install.manifest"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d_%H%M%S)"
LOG_FILE="$DOTFILES_DIR/install.log"
DRY_RUN=false
SYNC_STRICT=false
AUR_HELPER=""

# ═══════════════════════════════════════════════════════════════
# Logging
# ═══════════════════════════════════════════════════════════════

log()        { printf '[INSTALL] %s\n' "$*" | tee -a "$LOG_FILE"; }
log_stage()  { printf '\n\033[1m── %s ──\033[0m\n' "$*" | tee -a "$LOG_FILE"; }
log_ok()     { printf '  [\033[32m OK \033[0m] %s\n' "$*" | tee -a "$LOG_FILE"; }
log_warn()   { printf '  [\033[33mWARN\033[0m] %s\n' "$*" | tee -a "$LOG_FILE"; }
log_fail()   { printf '  [\033[31mFAIL\033[0m] %s\n' "$*" | tee -a "$LOG_FILE"; }

die() { log_fail "$*"; exit 1; }

# ═══════════════════════════════════════════════════════════════
# Argument parsing
# ═══════════════════════════════════════════════════════════════

usage() {
    cat <<EOF
Usage: ./install [OPTIONS]

Options:
  --dry-run       Show what would happen without making changes
  --sync-strict   Enable rsync --delete for config dirs (destructive)
  -h, --help      Show this help

The script reads config/install.manifest to determine what to install.
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)      DRY_RUN=true; shift ;;
            --sync-strict)  SYNC_STRICT=true; shift ;;
            -h|--help)      usage; exit 0 ;;
            *)              die "Unknown flag: $1. Use --help for usage." ;;
        esac
    done
}

# ═══════════════════════════════════════════════════════════════
# Preflight checks
# ═══════════════════════════════════════════════════════════════

preflight() {
    log_stage "Preflight"

    # Verify we're in the dotfiles repo
    [[ -f "$MANIFEST" ]] || die "Manifest not found: $MANIFEST"
    [[ -d "$DOTFILES_DIR/config" && -d "$DOTFILES_DIR/bin" ]] || die "Not in dotfiles repo"

    # Don't run as root
    [[ $EUID -ne 0 ]] || die "Don't run as root"

    # Required tools (skip in dry-run mode)
    if ! $DRY_RUN; then
        command -v rsync &>/dev/null || die "rsync not found. Install with: sudo pacman -S rsync"
    else
        command -v rsync &>/dev/null || log_warn "rsync not found (dry-run mode, will skip actual installs)"
    fi

    # AUR helper (skip in dry-run mode)
    if ! $DRY_RUN; then
        if command -v yay &>/dev/null; then
            AUR_HELPER=yay
        elif command -v paru &>/dev/null; then
            AUR_HELPER=paru
        else
            die "Neither yay nor paru found. Install one first."
        fi
        log_ok "AUR helper: $AUR_HELPER"
    else
        log_warn "AUR helper not checked (dry-run mode)"
    fi
}

# ═══════════════════════════════════════════════════════════════
# Manifest parser
# ═══════════════════════════════════════════════════════════════

parse_manifest() {
    CONFIG_DIRS=()
    HOME_FILES=()
    HOME_DIRS=()

    local section=""
    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// /}" ]] && continue

        # Section headers
        if [[ "$line" =~ ^([a-zA-Z_]+): ]]; then
            section="${BASH_REMATCH[1]}"
            continue
        fi

        # List items
        if [[ "$line" =~ ^[[:space:]]*-[[:space:]]+(.+) ]]; then
            local item="${BASH_REMATCH[1]}"
            case "$section" in
                config_dirs) CONFIG_DIRS+=("$item") ;;
                home_files)  HOME_FILES+=("$item") ;;
                home_dirs)   HOME_DIRS+=("$item") ;;
            esac
        fi
    done < "$MANIFEST"

    log_ok "Manifest: ${#CONFIG_DIRS[@]} config dirs, ${#HOME_FILES[@]} home files, ${#HOME_DIRS[@]} home dirs"
}

# ═══════════════════════════════════════════════════════════════
# Backup
# ═══════════════════════════════════════════════════════════════

backup_file() {
    local src="$1"
    [[ -e "$src" || -L "$src" ]] || return 0

    local rel="${src#$HOME/}"
    local dest="$BACKUP_DIR/$rel"

    if $DRY_RUN; then
        log "[DRY-RUN] Would back up: $rel"
        return 0
    fi

    mkdir -p "$(dirname "$dest")"

    # rsync preserves symlinks, ACLs, xattrs, permissions
    if rsync -aHAX --numeric-ids "$src" "$dest" 2>/dev/null; then
        log_ok "Backed up: $rel"
    else
        # Last resort: mv (same filesystem only)
        if mv "$src" "$dest" 2>/dev/null; then
            log_ok "Backed up (mv): $rel"
        else
            log_warn "Failed to back up: $rel"
            return 1
        fi
    fi
}

# ═══════════════════════════════════════════════════════════════
# Deploy: config/home/ → ~/
# ═══════════════════════════════════════════════════════════════

deploy_home() {
    log_stage "Deploy home files"
    local src="$DOTFILES_DIR/config/home"

    # Explicit file list (from manifest)
    for file in "${HOME_FILES[@]}"; do
        local src_path="$src/$file"
        local dest_path="$HOME/$file"

        [[ -f "$src_path" ]] || { log_warn "Source missing: $file"; continue; }

        backup_file "$dest_path" || true
        if $DRY_RUN; then
            log "[DRY-RUN] Would install: $file → ~/"
        else
            rsync -a "$src_path" "$dest_path"
            log_ok "Installed: $file → ~/"
        fi
    done

    # Explicit directory list (from manifest)
    for dir in "${HOME_DIRS[@]}"; do
        local src_path="$src/$dir"
        local dest_path="$HOME/$dir"

        [[ -d "$src_path" ]] || { log_warn "Source missing: $dir"; continue; }

        backup_file "$dest_path" || true
        if $DRY_RUN; then
            log "[DRY-RUN] Would install: $dir/ → ~/"
        else
            rsync -a "$src_path/" "$dest_path/"
            log_ok "Installed: $dir/ → ~/"
        fi
    done
}

# ═══════════════════════════════════════════════════════════════
# Deploy: config/<dirs>/ → ~/.config/
# ═══════════════════════════════════════════════════════════════

deploy_config() {
    log_stage "Deploy config directories"
    local src="$DOTFILES_DIR/config"
    local rsync_flags=(-a)

    $SYNC_STRICT && rsync_flags+=(--delete)

    for dir in "${CONFIG_DIRS[@]}"; do
        local src_path="$src/$dir"
        local dest_path="$HOME/.config/$dir"

        [[ -d "$src_path" ]] || { log_warn "Source missing: $dir"; continue; }

        backup_file "$dest_path" || true
        if $DRY_RUN; then
            log "[DRY-RUN] Would install: $dir/ → ~/.config/"
        else
            mkdir -p "$dest_path"
            rsync "${rsync_flags[@]}" "$src_path/" "$dest_path/"
            log_ok "Installed: $dir/ → ~/.config/"
        fi
    done

    # Warn about unlisted dirs in config/
    for dir_path in "$src"/*/; do
        local dir_name
        dir_name="$(basename "$dir_path")"
        [[ "$dir_name" == "home" ]] && continue

        local listed=false
        for known in "${CONFIG_DIRS[@]}"; do
            [[ "$dir_name" == "$known" ]] && listed=true && break
        done

        if ! $listed; then
            log_warn "Unlisted config dir: config/$dir_name (add to install.manifest to include)"
        fi
    done
}

# ═══════════════════════════════════════════════════════════════
# Deploy: bin/ → ~/.local/bin/
# ═══════════════════════════════════════════════════════════════

deploy_bin() {
    log_stage "Deploy scripts"
    local src="$DOTFILES_DIR/bin"
    local dest="$HOME/.local/bin"

    mkdir -p "$dest"

    for script in "$src"/*; do
        [[ -f "$script" ]] || continue
        local name
        name="$(basename "$script")"

        backup_file "$dest/$name" || true
        if $DRY_RUN; then
            log "[DRY-RUN] Would install: bin/$name → ~/.local/bin/"
        else
            rsync -a "$script" "$dest/$name"
            chmod +x "$dest/$name"
            log_ok "Installed: bin/$name"
        fi
    done

    # Warn about stale scripts in ~/.local/bin that aren't in repo
    for existing in "$dest"/*; do
        [[ -f "$existing" ]] || continue
        local name
        name="$(basename "$existing")"

        local in_repo=false
        for repo_script in "$src"/*; do
            [[ "$(basename "$repo_script")" == "$name" ]] && in_repo=true && break
        done

        if ! $in_repo; then
            log_warn "Stale script: ~/.local/bin/$name (not in repo)"
        fi
    done
}

# ═══════════════════════════════════════════════════════════════
# Dependencies
# ═══════════════════════════════════════════════════════════════

install_deps() {
    log_stage "Install dependencies"

    local CORE_PKGS=(
        # Desktop
        hyprland-git
        quickshell-git
        kitty

        # Shell
        zsh
        fzf

        # Wayland utilities
        grim
        slurp
        wl-clipboard
        xdg-desktop-portal
        xdg-desktop-portal-hyprland

        # PipeWire audio stack
        pipewire
        pipewire-pulse
        wireplumber

        # Fonts
        ttf-jetbrains-mono-nerd
        ttf-roboto
	ttf-noto-nerd

        # Theming
        awww
        matugen
        qt6ct

        # System
        jq
        brightnessctl
        playerctl
        python
        python-jinja

	# Other utilites
	proton-vpn-cli
	proton-vpn-gtk-app
    )

    local OPTIONAL_PKGS=(
        # Music
        mpd
        ncmpcpp
        mpc

        # Polkit
        hyprpolkitagent-git

        # File manager
        dolphin

        # Python tools
        python-eyed3
        yt-dlp

        # Misc
        libnotify
        glib2
    )

    if $DRY_RUN; then
        log "[DRY-RUN] Would install ${#CORE_PKGS[@]} core + ${#OPTIONAL_PKGS[@]} optional packages"
        return
    fi

    # Core packages: fail on error
    log "Installing core packages..."
    if $AUR_HELPER -S --needed --noconfirm "${CORE_PKGS[@]}" 2>&1 | tee -a "$LOG_FILE"; then
        log_ok "Core packages installed"
    else
        die "Core package installation failed"
    fi

    # Optional packages: warn on error, don't abort
    log "Installing optional packages..."
    if $AUR_HELPER -S --needed --noconfirm "${OPTIONAL_PKGS[@]}" 2>&1 | tee -a "$LOG_FILE"; then
        log_ok "Optional packages installed"
    else
        log_warn "Some optional packages failed (non-fatal)"
    fi
}

# ═══════════════════════════════════════════════════════════════
# Post-install
# ═══════════════════════════════════════════════════════════════

post_install() {
    log_stage "Post-install"

    if ! $DRY_RUN; then
        # Font cache
        fc-cache -fv 2>&1 | tail -1 | tee -a "$LOG_FILE"
        log_ok "Font cache updated"

        # XDG user dirs
        xdg-user-dirs-update 2>/dev/null && log_ok "XDG user dirs updated" || true
    fi

    # Summary
    log ""
    log "=== Summary ==="
    log "  Config dirs: ${#CONFIG_DIRS[@]}"
    log "  Home files:  ${#HOME_FILES[@]}"
    log "  Home dirs:   ${#HOME_DIRS[@]}"
    log "  Backup:      $BACKUP_DIR"
    log ""
    log "To apply changes:"
    log "  1. Log out and back in (or exec zsh)"
    log "  2. hyprctl reload  (if Hyprland is running)"
    log "  3. Open a new terminal for shell changes"
}

# ═══════════════════════════════════════════════════════════════
# Error handling
# ═══════════════════════════════════════════════════════════════

cleanup() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        log ""
        log_fail "Installation failed (exit $exit_code)"
        log_fail "Partial install may exist. Backups: $BACKUP_DIR"
        log_fail "Check $LOG_FILE for details"
    fi
}

trap cleanup EXIT
trap 'die "Interrupted"' INT TERM

# ═══════════════════════════════════════════════════════════════
# Main
# ═══════════════════════════════════════════════════════════════

main() {
    parse_args "$@"
    : > "$LOG_FILE"  # truncate log

    preflight
    parse_manifest

    # Single confirmation
    log ""
    log "This will install your dotfiles:"
    log "  Config dirs: ${CONFIG_DIRS[*]}"
    log "  Home files:  ${HOME_FILES[*]}"
    log "  Home dirs:   ${HOME_DIRS[*]}"
    log "  Backup:      $BACKUP_DIR"
    log ""
    read -rp "Proceed? [y/N] " confirm
    [[ "$confirm" =~ ^[yY] ]] || { log "Aborted."; exit 0; }

    install_deps
    deploy_home
    deploy_config
    deploy_bin
    post_install
}

main "$@"
