#!/usr/bin/env sh
#
# Prompts you for keywords to your local files, directories or Google search and launches them respectively.
# Dependencies: grep, sed, find, awk, file, xargs

MAXDEPTH=11
SEARCHLIST=/tmp/searchlist

BROWSER=brave
EDITOR=nvim
HOME_DIR=/home/dsoukup

#========================================================
# Modify this section according to your preference
#========================================================
launch() {
   # Find out the mimetype of the file you wannna launch
   case $(file --mime-type "$1" -bL) in
      # Launch using your favorite programs
      video/*)
         mpv "$1"
         ;;
      image/svg+xml)
         ristretto "$1"
         ;;
      application/pdf | application/epub+zip)
         zathura "$1"
         ;;
      text/* | inode/x-empty | application/json | application/octet-stream)
         alacritty -e "$EDITOR" "$1"
         ;;
      inode/directory)
         alacritty -e "$EDITOR" "$*"
         # st lf "$*"
         ;;
   esac
}

search_n_launch() {
   RESULT=$(grep "$1" "$SEARCHLIST" | head -1)
   if [ -n "$RESULT" ]; then
      launch "$RESULT"
   else
      "$BROWSER" duckduckgo.com/\?q="$1"
   fi
}

get_config() {
   while IFS= read -r line; do
      if [[ ${line:0:1} != "#" ]] then
         echo "$line"
      fi
   done < "$1"
}

dmenu_search() {
  # get the folder before home to change it to ~/
   HDIR=$(echo "$HOME_DIR" | awk -F / '{print $NF}')
   QUERY=$(awk -F / -v HDIR=$HDIR '{
   if (NF > 5)
      if ($(NF - 1) == HDIR)
         printf "%s\n", $NF
      if ($(NF - 2) == HDIR)
         printf "%s/%s\n", $(NF - 1), $NF
      else if ($(NF - 3) == HDIR)
         printf "%s/%s/%s\n", $(NF - 2), $(NF - 1), $NF
      else if ($(NF - 4) == HDIR)
         printf "%s/%s/%s/%s\n", $(NF - 3), $(NF - 2), $(NF - 1), $NF
      else if ($(NF - 5) == HDIR)
         printf "%s/%s/%s/%s/%s\n", $(NF -4), $(NF - 3), $(NF - 2), $(NF - 1), $NF
   else
      printf "%s/%s/%s/%s/%s\n", $(NF - 4), $(NF - 3), $(NF - 2), $(NF - 1), $NF
   }' "$SEARCHLIST" | "$1") &&
      search_n_launch "$QUERY"
}

run_dmenu() {
   dmenu -i
}

run_rofi() {
   rofi -sort true -sorting-method fzf -dmenu -i -p "Bolt"
}

fzf_search() {
   QUERY=$(awk -F / '{print $(NF-1)"/"$NF}' "$SEARCHLIST" |
      fzf -e -i \
         --reverse \
         --border \
         --margin 15%,25% \
         --info hidden \
         --bind=tab:down,btab:up \
         --prompt "launch ") &&
      search_n_launch "$QUERY"
}

watch() {
   grep -v "^#" ~/.config/bolt/paths |
      xargs inotifywait -m -r -e create,delete,move |
      while read -r line; do
         generate
      done &
}

generate() {
   FILTERS=$(get_config ~/.config/bolt/filters | awk '{printf "%s\\|",$0;}' | sed -e 's/|\./|\\./g' -e 's/\\|$//g')
   get_config ~/.config/bolt/paths |
      xargs -I% find % -maxdepth $MAXDEPTH -type f\
         ! -regex ".*\($FILTERS\).*" > "$SEARCHLIST"
}

while :; do
   case $1 in
      --generate) generate ;;
      --fzf-search) fzf_search ;;
      --launch) launch "$2" ;;
      --rofi-search) dmenu_search "run_rofi" ;;
      --dmenu-search) dmenu_search "run_dmenu" ;;
      --watch) watch ;;
      *) break ;;
   esac
   shift
done
