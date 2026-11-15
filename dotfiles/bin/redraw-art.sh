#!/bin/bash
cache="$(cat /tmp/mpd-cache-path.txt 2>/dev/null)"
[ -z "$cache" ] && exit
[ ! -s "$cache" ] && exit
[ -p "$FIFO_UEBERZUG" ] || exit

geo="$(tmux list-panes -t ncmpcppplayer -F '#{pane_index} #{pane_left} #{pane_top} #{pane_width} #{pane_height}' 2>/dev/null | awk '$1==1')"
[ -z "$geo" ] && exit

art_x="$(echo "$geo" | awk '{print $2}')"
art_y="$(echo "$geo" | awk '{print $3}')"
art_width="$(echo "$geo" | awk '{print $4}')"
art_height="$(echo "$geo" | awk '{print $5}')"

json="{\"action\":\"add\","
json="${json}\"identifier\":\"albumart\","
json="${json}\"x\":${art_x},"
json="${json}\"y\":${art_y},"
json="${json}\"width\":${art_width},"
json="${json}\"height\":${art_height},"
json="${json}\"path\":\"${cache}\"}"
printf '{"action":"remove","identifier":"albumart"}\n' > "$FIFO_UEBERZUG"
sleep 0.05
printf '%s\n' "$json" > "$FIFO_UEBERZUG"

tmux refresh-client -S 2>/dev/null
