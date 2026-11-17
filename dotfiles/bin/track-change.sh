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
rm -f "$cache"

ffmpeg -nostdin -y -loglevel quiet -i "${music_dir}/${file}" -an -vcodec copy -f image2 "$cache" 2>/dev/null

if [ ! -s "$cache" ]; then
        rm -f "$cache"
        img="$(find "$folder" -maxdepth 1 -type f -iregex '.*\.\(jpe?g\|png\|webp\|gif\|bmp\)' | sort |
                awk '{ a[NR] = $0 } tolower($0) ~ /\/(cover|folder|front|album)[^\/]*$/ { print; f = 1; exit } END { if (!f && NR) print a[1] }')"
        [ -n "$img" ] && cp "$img" "$cache"
fi

echo "$cache" > /tmp/mpd-cache-path.txt

~/.local/bin/redraw-art.sh

tmux refresh-client -S 2>/dev/null
