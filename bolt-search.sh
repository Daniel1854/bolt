#!/usr/bin/env sh

[ "$SEARCH_LIST" ] || export SEARCH_LIST=/tmp/search_list

awk -F / '{print $NF}' "$SEARCH_LIST" |
    rofi -sort true -sorting-method fzf -dmenu -i -p Open |
    xargs -I% grep /%$ "$SEARCH_LIST" |
    xargs bolt-launch