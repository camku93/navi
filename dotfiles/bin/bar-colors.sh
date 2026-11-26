#!/bin/sh

BAR_TEXT="#e8eaf0"
BAR_ACCENT="#b8567f"
BAR_MUTED="#4d2735"

bar_block() {
	printf '^c%s^%s^d^' "$BAR_ACCENT" "$1"
	[ -n "$2" ] && printf ' ^c%s^%s^d^' "${3:-$BAR_TEXT}" "$2"
	printf ' ^c%s^·^d^ \n' "$BAR_MUTED"
}

bar_button() {
	printf '^c%s^ %s^d^%s \n' "$BAR_ACCENT" "$1" "${2:+ $2}"
}
