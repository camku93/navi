#!/bin/sh
export TERMINAL=st
export XDG_CURRENT_DESKTOP=navi
export EDITOR=vim
export PATH="$HOME/.local/bin:$PATH"
if [ -f "$HOME/.config/navi/use-zsh" ] && command -v zsh >/dev/null 2>&1; then
        export SHELL=$(command -v zsh)
        export ZDOTDIR="$HOME/.config/navi/zsh"
fi
(while ! pgrep -x dwm >/dev/null; do sleep 0.1; done; sleep 0.5; dwmblocks) &
picom &
dunst &
display-autorevert &
feh --bg-fill ~/Pictures/Wallpapers/wallpaper.jpg &
if [ ! -d /run/systemd/system ]; then
  if ! rc-update -U show 2>/dev/null | grep -q wireplumber; then
    pgrep -x pipewire >/dev/null || pipewire &
    i=0
    while [ ! -S "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/pipewire-0" ] && [ "$i" -lt 50 ]; do
      sleep 0.1
      i=$((i + 1))
    done
    pgrep -x wireplumber >/dev/null || wireplumber &
    pgrep -x pipewire-pulse >/dev/null || pipewire-pulse &
  fi
fi
pgrep -x mpd >/dev/null || mpd
mbsync-loop &
xset dpms 0 0 900
xset +fp /usr/share/fonts/misc
xset fp rehash
exec dwm
