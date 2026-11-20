#!/bin/bash

set -u

NAVI_DIR=$(cd "$(dirname "$0")" && pwd)
STAMP=$(date +%Y%m%d-%H%M%S)
BACKUP="$HOME/.navi-backup-$STAMP"
MISSING=()
INIT=unknown

say()  { printf '\n\033[1;35m==> %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m!! %s\033[0m\n' "$*" >&2; }
die()  { printf '\033[1;31mxx %s\033[0m\n' "$*" >&2; exit 1; }

banner() {
        local p=$'\033[1;38;2;184;86;127m' w=$'\033[1;38;2;232;234;240m'
        local s=$'\033[38;2;139;154;184m' r=$'\033[0m' a b
        printf '\n'
        while IFS='|' read -r a b; do
                printf '  %s%s%s%s%s\n' "$p" "$a" "$w" "$b" "$r"
        done <<'EOF'
                    |                                     ▐▌
                    |
▀▙▄                 | ▐▙▞▀▀▚▄    ▄▀▀▀▀▀▚▖   █      ▐▌   ▀▀▜▌
  ▝▀▙▄▖             | ▐▌    █          ▐▌   ▝▙    ▗▛      ▐▌
      █▌            | ▐▌    █    ▄▀▀▀▀▀▜▌    ▝▙  ▗▛       ▐▌
  ▗▄▛▀▘             | ▐▌    █    █     ▐▌     ▝▙▗▛        ▐▌
▄▛▀                 | ▐▌    █    ▝▚▄▄▄▞▜▌      ▝█▘     ▄▄▄▟▙▄▄▄
           ▀▀▀▀▀▀▀▀ |
EOF
        printf '%23s%sNimble Arch Visual Interface%s\n\n' '' "$s" "$r"
}

confirm() {
        local ans=
        printf 'Proceed with installation? [Y/n] '
        read -r ans </dev/tty || ans=
        case $ans in
        [Nn]*) printf 'Installation cancelled.\n'; exit 0 ;;
        esac
}

check_environment() {
	[ "$(id -u)" -ne 0 ] || die "Run this as your normal user, not root."
	command -v pacman >/dev/null 2>&1 || die "pacman not found. Navi needs an Arch-based system."
	command -v sudo   >/dev/null 2>&1 || die "sudo is not installed. Install it and add your user to sudoers."
	sudo -v || die "sudo failed."
}

detect_init() {
	if [ -d /run/systemd/system ]; then
		INIT=systemd
	elif command -v rc-service >/dev/null 2>&1; then
		INIT=openrc
	elif command -v sv >/dev/null 2>&1; then
		INIT=runit
	fi
	say "Init system: $INIT"
}

# enable_service SYSTEMD_NAME OPENRC_NAME RUNIT_NAME
enable_service() {
	local sd=$1 orc=$2 rv=$3
	case $INIT in
	systemd)
		sudo systemctl enable --now "$sd.service" || warn "Could not enable $sd" ;;
	openrc)
		sudo rc-update add "$orc" default >/dev/null 2>&1
		sudo rc-service "$orc" start >/dev/null 2>&1 || warn "Could not start $orc (it may already run)" ;;
	runit)
		local dir
		for dir in /run/runit/service /etc/runit/runsvdir/default /var/service; do
			if [ -d "$dir" ] && [ -d "/etc/runit/sv/$rv" ]; then
				sudo ln -sf "/etc/runit/sv/$rv" "$dir/" && return 0
			fi
		done
		warn "Could not enable $rv (no runit service directory found)" ;;
	*)
		warn "Unknown init system: enable $sd yourself." ;;
	esac
}

install_packages() {
	say "Updating the system"
	if [ "${NAVI_SKIP_UPDATE:-0}" != 1 ]; then
		sudo pacman -Syu --noconfirm || warn "System update failed, continuing."
	fi

	say "Installing packages"
	local avail=() p
	while read -r p; do
		case $p in ''|'#'*) continue ;; esac
# Skip anything the system already provides
	[ -z "$(pacman -T "$p")" ] && continue
		if pacman -Si "$p" >/dev/null 2>&1; then
			avail+=("$p")
		else
			MISSING+=("$p")
		fi
	done < "$NAVI_DIR/packages.txt"

	case $INIT in
	openrc|runit)
		for p in networkmanager cups chrony elogind; do
			pacman -Si "$p-$INIT" >/dev/null 2>&1 && avail+=("$p-$INIT")
		done ;;
	esac

        if ! sudo pacman -S --needed --noconfirm "${avail[@]}"; then
                warn "Batch install failed, trying packages one at a time."
                for p in "${avail[@]}"; do
                        sudo pacman -S --needed --noconfirm "$p" || MISSING+=("$p")
                done
        fi
}

setup_services() {
	say "Enabling services"
	if [ "$INIT" != systemd ]; then
		enable_service dbus dbus dbus
		enable_service elogind elogind elogind
	fi
	enable_service NetworkManager NetworkManager NetworkManager
	enable_service cups cupsd cupsd
	# The OpenRC chrony service is called "chrony" on some distros, "chronyd" on others
	local chrony_rc=chronyd
	[ -e /etc/init.d/chrony ] && chrony_rc=chrony
	enable_service chronyd "$chrony_rc" chrony
}

setup_groups() {
	say "Adding $USER to the video and audio groups"
	sudo usermod -aG video,audio "$USER"
}

install_sources() {
	say "Building dwm, dwmblocks, st and slock"
	mkdir -p "$HOME/.local/src"
	local d
	for d in dwm dwmblocks st slock; do
		if [ -d "$HOME/.local/src/$d" ]; then
			mkdir -p "$BACKUP/src"
			mv "$HOME/.local/src/$d" "$BACKUP/src/$d"
		fi
		cp -r "$NAVI_DIR/src/$d" "$HOME/.local/src/$d"
		( cd "$HOME/.local/src/$d" && make clean >/dev/null 2>&1; make && sudo make install ) \
			|| warn "Build of $d failed."
	done
}

install_mutt_wizard() {
	command -v mw >/dev/null 2>&1 && return 0
	say "Installing mutt-wizard (not configured, run: mw -a you@example.com)"
	local dir="$HOME/.local/src/mutt-wizard"
	[ -d "$dir" ] || git clone --depth 1 https://github.com/LukeSmithxyz/mutt-wizard "$dir" \
		|| { warn "Could not download mutt-wizard."; return 1; }
	( cd "$dir" && sudo make install ) || warn "mutt-wizard install failed."
}

install_nvchad() {
	[ -d "$HOME/.config/nvim" ] && return 0
	say "Installing NvChad (it finishes setting itself up the first time you run nvim)"
	git clone --depth 1 https://github.com/NvChad/starter "$HOME/.config/nvim" \
		&& rm -rf "$HOME/.config/nvim/.git" \
		|| warn "Could not download NvChad."
}

# other_desktop_present
other_desktop_present() {
        local f
        for f in /usr/share/xsessions/*.desktop /usr/share/wayland-sessions/*.desktop; do
                [ -e "$f" ] || continue
                [ "${f##*/}" = navi.desktop ] && continue
                return 0
        done
        return 1
}

# copy_tree SRC DST BACKUP: copy every file under SRC into DST
copy_tree() {
	local src=$1 dst=$2 bak=$3 skip=${4:-no-skip} f
	while IFS= read -r -d '' f; do
                        case $f in $skip) continue ;; esac
		if [ -e "$dst/$f" ] && ! cmp -s "$src/$f" "$dst/$f"; then
			mkdir -p "$bak/$(dirname "$f")"
			cp -a "$dst/$f" "$bak/$f"
		fi
		mkdir -p "$dst/$(dirname "$f")"
		cp -p "$src/$f" "$dst/$f"
	done < <(cd "$src" && find . -type f -print0)
}

install_dotfiles() {
	say "Installing configs (existing files are saved in $BACKUP)"
	mkdir -p "$HOME/.config" "$HOME/.local/bin" "$HOME/Documents" \
		"$HOME/Pictures/Wallpapers" "$HOME/Music" "$HOME/.config/mpd/playlists"
	[ -e "$HOME/.config/mpd/state" ] || touch "$HOME/.config/mpd/state"

        local skip='no-skip'
        if other_desktop_present; then
                skip='./gtk-[34].0/*'
                say "Another desktop is installed, so GTK theme settings are left alone"
        fi
        copy_tree "$NAVI_DIR/dotfiles/config" "$HOME/.config" "$BACKUP/config" "$skip"
        if cmp -s "$HOME/.config/mimeapps.list" "$NAVI_DIR/dotfiles/config/navi-mimeapps.list"; then
                mkdir -p "$BACKUP/config"
                mv "$HOME/.config/mimeapps.list" "$BACKUP/config/mimeapps.list"
        fi
	copy_tree "$NAVI_DIR/dotfiles/bin" "$HOME/.local/bin" "$BACKUP/bin"
        copy_tree "$NAVI_DIR/dotfiles/applications" "$HOME/.local/share/applications" "$BACKUP/applications"
        local lfd="$HOME/.local/share/applications/lf.desktop"
        if [ -f /usr/share/applications/lf.desktop ] && { [ ! -e "$lfd" ] || grep -q '^NotShowIn=navi;' "$lfd"; }; then
                sed '/^\[Desktop Entry\]/a NotShowIn=navi;' /usr/share/applications/lf.desktop > "$lfd"
        fi

	local f
	for f in .xinitrc .Xresources; do
		[ -f "$NAVI_DIR/dotfiles/home/$f" ] || continue
		if [ -e "$HOME/$f" ]; then
			mkdir -p "$BACKUP/home"
			cp -a "$HOME/$f" "$BACKUP/home/$f"
		fi
		cp "$NAVI_DIR/dotfiles/home/$f" "$HOME/$f"
	done
	chmod +x "$HOME/.xinitrc"

        if [ -e "$HOME/Documents/Navi-Keybinds.pdf" ]; then
                mkdir -p "$BACKUP/home"
                cp -a "$HOME/Documents/Navi-Keybinds.pdf" "$BACKUP/home/Navi-Keybinds.pdf"
        fi
        cp "$NAVI_DIR/docs/KEYBINDS.pdf" "$HOME/Documents/Navi-Keybinds.pdf"
        cp "$NAVI_DIR/wallpapers/wallpaper.jpg" "$HOME/Pictures/Wallpapers/wallpaper.jpg"

}

install_system_files() {
	say "Installing system files"

	sudo install -Dm644 "$NAVI_DIR/system/30-touchpad.conf" /etc/X11/xorg.conf.d/30-touchpad.conf

	# Index the X bitmap fonts (slock uses Terminus)
	if [ -d /usr/share/fonts/misc ] && command -v mkfontscale >/dev/null 2>&1; then
		sudo mkfontscale /usr/share/fonts/misc
		sudo mkfontdir /usr/share/fonts/misc
	fi

	local tmp rb po
	rb=$(command -v reboot); po=$(command -v poweroff)
	if [ -n "$rb" ] && [ -n "$po" ]; then
		tmp=$(mktemp)
		printf '%s ALL=(ALL) NOPASSWD: %s, %s\n' "$USER" "$rb" "$po" > "$tmp"
		if sudo visudo -cf "$tmp" >/dev/null 2>&1; then
			sudo install -m440 "$tmp" /etc/sudoers.d/navi
		else
			warn "Could not validate the sudoers rule, skipped."
		fi
		rm -f "$tmp"
	fi

	# Session entry
	tmp=$(mktemp)
	printf '[Desktop Entry]\nName=Navi\nComment=Navi dwm session\nExec=%s/.xinitrc\nType=Application\n' "$HOME" > "$tmp"
	sudo install -Dm644 "$tmp" /usr/share/xsessions/navi.desktop
	rm -f "$tmp"
}

set_shell() {
        command -v zsh >/dev/null 2>&1 || return 0
        [ -e "$HOME/.config/navi/zsh-set" ] && return 0
        mkdir -p "$HOME/.config/navi"
        : > "$HOME/.config/navi/use-zsh"
        : > "$HOME/.config/navi/zsh-set"
}

has_display_manager() {
        [ -e /etc/systemd/system/display-manager.service ] && return 0
        local dm
        for dm in sddm gdm lightdm lxdm ly ly-dm greetd slim; do
                command -v "$dm" >/dev/null 2>&1 && return 0
        done
        return 1
}

setup_autostart() {
        local sh f
        sh=$(getent passwd "$USER" | cut -d: -f7)
        case $sh in
        */bash) f="$HOME/.bash_profile" ;;
        */zsh) f="$HOME/.zprofile" ;;
        *) return 0 ;;
        esac
        has_display_manager && return 0
        grep -qs 'navi-autostart' "$f" && return 0
        case $sh in
        */bash) [ -e "$f" ] || printf '[[ -f ~/.bashrc ]] && . ~/.bashrc\n' > "$f" ;;
        esac
        printf '\n# navi-autostart\nif [ -z "$DISPLAY" ] && [ "$XDG_VTNR" = "1" ]; then exec startx; fi\n' >> "$f"
}

build_aur() {
        local pkg=$1 url dir rc=0
        url="https://aur.archlinux.org/$pkg.git"
        dir=$(mktemp -d) || return 1
        git clone --depth 1 "$url" "$dir/pkg" || rc=1
        if [ $rc -eq 0 ]; then
                ( cd "$dir/pkg" && makepkg -si --noconfirm ) || rc=1
        fi
        rm -rf "$dir"
        return $rc
}

install_aur() {
        local id=""
        [ -r /etc/os-release ] && id=$(. /etc/os-release; echo "${ID:-}")
        if [ "$id" = parabola ]; then
                MISSING+=(yay abook)
                return 0
        fi

        say "Installing yay and abook"
        if ! command -v yay >/dev/null 2>&1; then
                if pacman -Si yay >/dev/null 2>&1; then
                        sudo pacman -S --needed --noconfirm yay
                else
                        build_aur yay-bin
                fi
        fi
        command -v yay >/dev/null 2>&1 || MISSING+=(yay)

        command -v abook >/dev/null 2>&1 && return 0
        if pacman -Si abook >/dev/null 2>&1; then
                sudo pacman -S --needed --noconfirm abook
        elif command -v yay >/dev/null 2>&1; then
                yay -S --needed --noconfirm abook
        fi
        command -v abook >/dev/null 2>&1 || MISSING+=(abook)
}

record_install() {
        mkdir -p "$HOME/.config/navi"
        printf '%s\n' "$NAVI_DIR" > "$HOME/.config/navi/repo"
        git -C "$NAVI_DIR" rev-parse HEAD > "$HOME/.config/navi/version" 2>/dev/null \
                || rm -f "$HOME/.config/navi/version"
}

finish() {
	say "Done"
	if [ "${#MISSING[@]}" -gt 0 ]; then
		warn "Could not be installed (install them another way if you want them):"
		printf '   %s\n' "${MISSING[@]}" >&2
	fi
	cat <<MSG

Navi is installed.
  - Old versions of any files it replaced are in: $BACKUP
  - Press Super+F1 for the keybinds.
  - To update Navi later, press Super+Shift+U.
  - Mail is installed but not set up. When you want it:  mw -a you@example.com
  - Run nvim once so NvChad can finish setting itself up.
MSG
}

banner
confirm
check_environment
detect_init
install_packages
install_aur
setup_services
setup_groups
install_sources
install_mutt_wizard
install_nvchad
install_dotfiles
install_system_files
set_shell
setup_autostart
record_install
finish
