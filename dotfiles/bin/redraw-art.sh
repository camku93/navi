#!/bin/bash
if [ "$1" = note ]; then
        note() {
                local rows cols top left i=0 line
                rows="$(tput lines)" cols="$(tput cols)"
                top=$(( (rows - 8) / 2 )) left=$(( (cols - 16) / 2 ))
                [ "$top" -lt 0 ] && top=0
                [ "$left" -lt 0 ] && left=0
                printf '\033[2J\033[38;2;184;86;127m'
                while IFS= read -r line; do
                        printf '\033[%d;%dH%s' $((top + i + 1)) $((left + 1)) "$line"
                        i=$((i + 1))
                done <<'EOF'
     ▄▄▄▄▄▄▄▄▄▄▄
     █▀▀▀▀▀▀▀▀▀█
     █         █
     █         █
     █         █
 ▄▄▄▄█     ▄▄▄▄█
█████▌    █████▌
 ▀▀▀▀      ▀▀▀▀
EOF
                printf '\033[0m'
        }
        trap note WINCH
        printf '\033[?25l'
        note
        while :; do
                sleep 60 &
                wait $!
        done
fi

cache="$(cat /tmp/mpd-cache-path.txt 2>/dev/null)"
[ -p "$FIFO_UEBERZUG" ] || exit

pane="$(tmux list-panes -t ncmpcppv -F '#{pane_index} #{pane_id} #{pane_left} #{pane_top} #{pane_width} #{pane_height}' 2>/dev/null | awk '$1==1')"
[ -z "$pane" ] && exit
read -r _ id art_x art_y art_width art_height <<< "$pane"
state="$(tmux display-message -p -t "$id" '#{@art}')"

if [ -z "$cache" ] || [ ! -s "$cache" ]; then
        printf '{"action":"remove","identifier":"albumart"}\n' > "$FIFO_UEBERZUG"
        if [ "$state" != note ]; then
                tmux respawn-pane -k -t "$id" "$HOME/.local/bin/redraw-art.sh note"
                tmux set-option -p -t "$id" @art note
        fi
        exit
fi

if [ "$state" = note ]; then
        tmux respawn-pane -k -t "$id" "sleep infinity"
        tmux set-option -p -t "$id" @art ""
fi

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
