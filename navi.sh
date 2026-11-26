#!/bin/sh

set -e

if [ "$(id -u)" -eq 0 ]; then
	echo "Run this as your normal user, not root." >&2
	exit 1
fi

if ! command -v pacman >/dev/null 2>&1; then
	echo "Navi needs an Arch-based system (pacman not found)." >&2
	exit 1
fi

if ! command -v git >/dev/null 2>&1; then
	echo "Installing git..."
	sudo pacman -S --needed --noconfirm git
fi

dir="$HOME/navi"

if [ -d "$dir/.git" ] && [ -e "$HOME/.config/navi/repo" ]; then
	echo "Navi is already installed."
	echo "To update it, press Super+Shift+U or run navi-update."
	echo "Reinstalling replaces your configs with Navi's (your old ones are backed up)."
	printf 'Reinstall anyway? [y/N] '
	read -r ans </dev/tty || ans=
	case $ans in
	[Yy]*) ;;
	*) exit 0 ;;
	esac
fi

if [ -d "$dir/.git" ]; then
	echo "Updating $dir..."
	git -C "$dir" pull
else
	echo "Downloading Navi to $dir..."
	git clone https://github.com/camku93/navi "$dir"
fi

cd "$dir"
bash install.sh </dev/tty
