#!/bin/bash
music_dir="$HOME/Music"
cache="/tmp/mpd-current-cover.jpg"

file="$(mpc current -f %file%)"
if [ -z "$file" ]; then
        sleep 0.3
        file="$(mpc current -f %file%)"
fi
[ -z "$file" ] && exit

folder="$(dirname "${music_dir}/${file}")"

if [ -f "${folder}/cover.jpg" ]; then
        cp "${folder}/cover.jpg" "$cache"
else
        ffmpeg -y -loglevel quiet -i "${music_dir}/${file}" -an -vcodec copy "$cache" 2>/dev/null
fi

echo "$cache" > /tmp/mpd-cache-path.txt

~/.local/bin/redraw-art.sh

tmux refresh-client -S 2>/dev/null
