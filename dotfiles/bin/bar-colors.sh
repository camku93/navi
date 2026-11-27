#!/bin/sh

# shellcheck source=/dev/null
[ -f "$HOME/.config/navi/theme/colors.sh" ] && . "$HOME/.config/navi/theme/colors.sh"
BAR_TEXT=${navi_text:-#e8eaf0}
BAR_ACCENT=${navi_accent:-#b8567f}
BAR_MUTED=${navi_muted:-#4d2735}

bar_block() {
	printf '^c%s^%s^d^' "$BAR_ACCENT" "$1"
	[ -n "$2" ] && printf ' ^c%s^%s^d^' "${3:-$BAR_TEXT}" "$2"
	printf ' ^c%s^·^d^ \n' "$BAR_MUTED"
}

bar_button() {
	printf '^c%s^ %s^d^%s \n' "$BAR_ACCENT" "$1" "${2:+ $2}"
}
