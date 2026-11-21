# shellcheck shell=sh
# SPDX-License-Identifier: GPL-3.0-or-later
# Where each file in the repository is installed. Used by install.sh and navi-update.

other_desktop_present() {
	for f in /usr/share/xsessions/*.desktop /usr/share/wayland-sessions/*.desktop; do
		[ -e "$f" ] || continue
		[ "${f##*/}" = navi.desktop ] && continue
		return 0
	done
	return 1
}

navi_dest() {
	case $1 in
	dotfiles/config/gtk-[34].0/*)
		other_desktop_present && return 1
		printf '%s' "$HOME/.config/${1#dotfiles/config/}" ;;
	dotfiles/config/*) printf '%s' "$HOME/.config/${1#dotfiles/config/}" ;;
	dotfiles/bin/*) printf '%s' "$HOME/.local/bin/${1#dotfiles/bin/}" ;;
	dotfiles/applications/*) printf '%s' "$HOME/.local/share/applications/${1#dotfiles/applications/}" ;;
	dotfiles/home/.xinitrc | dotfiles/home/.Xresources) printf '%s' "$HOME/${1#dotfiles/home/}" ;;
	docs/KEYBINDS.pdf) printf '%s' "$HOME/Documents/Navi-Keybinds.pdf" ;;
	wallpapers/wallpaper.jpg) printf '%s' "$HOME/Pictures/Wallpapers/wallpaper.jpg" ;;
	src/dwm/* | src/dwmblocks/* | src/st/* | src/slock/*) printf '%s' "$HOME/.local/src/${1#src/}" ;;
	system/30-touchpad.conf) printf '%s' /etc/X11/xorg.conf.d/30-touchpad.conf ;;
	*) return 1 ;;
	esac
}
