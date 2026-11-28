#!/bin/sh
export TERMINAL=st
export XDG_CURRENT_DESKTOP=navi
export EDITOR=vim
export PATH="$HOME/.local/bin:$PATH"
export _JAVA_AWT_WM_NONREPARENTING=1
if [ -f "$HOME/.config/navi/use-zsh" ] && command -v zsh >/dev/null 2>&1; then
	SHELL=$(command -v zsh)
	export SHELL
	export ZDOTDIR="$HOME/.config/navi/zsh"
fi
[ -f "$HOME/.Xresources" ] && xrdb -merge "$HOME/.Xresources"
navi-theme --login
eval "$(navi-scale --apply)"
xsettingsd -c "$HOME/.config/navi/xsettingsd.conf" &
(while ! pgrep -x dwm >/dev/null; do sleep 0.1; done; sleep 0.5; dwmblocks) &
picom &
dunst &
display-autorevert &
setbg &
if [ ! -d /run/systemd/system ] && ! rc-update -U show 2>/dev/null | grep -q wireplumber; then
	pgrep -x pipewire >/dev/null || pipewire &
	i=0
	while [ ! -S "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/pipewire-0" ] && [ "$i" -lt 50 ]; do
		sleep 0.1
		i=$((i + 1))
	done
	pgrep -x wireplumber >/dev/null || wireplumber &
	pgrep -x pipewire-pulse >/dev/null || pipewire-pulse &
fi
pgrep -x mpd >/dev/null || mpd
(while mpc idle player >/dev/null; do pkill -RTMIN+11 dwmblocks; done) &
agents=$(systemctl --user list-units --state=active --plain --no-legend 'gpg-agent*' 2>/dev/null | awk '{print $1}')
# shellcheck disable=SC2086
[ -n "$agents" ] && systemctl --user stop $agents
gpgconf --kill gpg-agent
gpg-agent --daemon --default-cache-ttl 34560000 --max-cache-ttl 34560000 >/dev/null 2>&1
mbsync-loop &
navi-update-check --loop &
xset dpms 0 0 900
xset +fp /usr/share/fonts/misc
xset fp rehash
dwm
gpgconf --kill gpg-agent
# shellcheck disable=SC2086
[ -n "$agents" ] && systemctl --user start --no-block $agents
