#!/usr/bin/sh

# Color helpers
## colorize file syntax and display in less
p() {
  pygmentize "${1}" | less -r
}
alias pp=p

color_get() {
  ruby ~/.dotfiles/mac/color_picker.rb
}


#   This file echoes a bunch of color codes to the 
#   terminal to demonstrate what's available.  Each 
#   line is the color code of one forground color,
#   out of 17 (default + 16 escapes), followed by a 
#   test use of that color on all nine background 
#   colors (default + 8 escapes).
#
#   Source: http://www.faqs.org/docs/Linux-HOWTO/Bash-Prompt-HOWTO.html
colors() {
  T='gYw'   # The test text

  echo -e "\n                 40m     41m     42m     43m\
       44m     45m     46m     47m";

  for FGs in '    m' '   1m' '  30m' '1;30m' '  31m' '1;31m' '  32m' \
             '1;32m' '  33m' '1;33m' '  34m' '1;34m' '  35m' '1;35m' \
             '  36m' '1;36m' '  37m' '1;37m';
    do FG=${FGs// /}
    echo -en " $FGs \033[$FG  $T  "
    for BG in 40m 41m 42m 43m 44m 45m 46m 47m;
      do echo -en "$EINS \033[$FG\033[$BG  $T  \033[0m";
    done
    echo;
  done
  echo

  color(){
    for c; do
        printf '\e[48;5;%dm%03d' $c $c
    done
    printf '\e[0m \n'
  }

  IFS=$' \t\n'
  color {0..15}
  for ((i=0;i<6;i++)); do
      color $(seq $((i*36+16)) $((i*36+51)))
  done
  color {232..255}
}

# generates an 8 bit color table (256 colors) for reference,
# using the ANSI CSI+SGR \033[48;5;${val}m for background and
# \033[38;5;${val}m for text (see "ANSI Code" on Wikipedia)
#
colors_256() {
  echo -en "\n Add X+Y to get the ANSI code"
  echo -en "\n   +  "
  for i in {0..35}; do
    printf "%2b " $i
  done
  printf "\n\n %3b  " 0
  for i in {0..15}; do
    echo -en "\033[48;5;${i}m  \033[m "
  done
  #for i in 16 52 88 124 160 196 232; do
  for i in {0..6}; do
    let "i = i*36 +16"
    printf "\n\n %3b  " $i
    for j in {0..35}; do
      let "val = i+j"
      echo -en "\033[48;5;${val}m  \033[m "
    done
  done
  echo -e "\n"
}

# via https://unix.stackexchange.com/a/269085/14845
fromhex(){
    hex=${1#"#"}
    r=$(printf '0x%0.2s' "$hex")
    g=$(printf '0x%0.2s' ${hex#??})
    b=$(printf '0x%0.2s' ${hex#????})
    printf '%03d' "$(( (r<75?0:(r-35)/40)*6*6 +
                       (g<75?0:(g-35)/40)*6   +
                       (b<75?0:(b-35)/40)     + 16 ))"
}

tohex(){
    dec=$(($1%256))   ### input must be a number in range 0-255.
    if [ "$dec" -lt "16" ]; then
        bas=$(( dec%16 ))
        mul=128
        [ "$bas" -eq "7" ] && mul=192
        [ "$bas" -eq "8" ] && bas=7
        [ "$bas" -gt "8" ] && mul=255
        a="$((  (bas&1)    *mul ))"
        b="$(( ((bas&2)>>1)*mul ))"
        c="$(( ((bas&4)>>2)*mul ))"
        printf 'dec= %3s basic= #%02x%02x%02x\n' "$dec" "$a" "$b" "$c"
    elif [ "$dec" -gt 15 ] && [ "$dec" -lt 232 ]; then
        b=$(( (dec-16)%6  )); b=$(( b==0?0: b*40 + 55 ))
        g=$(( (dec-16)/6%6)); g=$(( g==0?0: g*40 + 55 ))
        r=$(( (dec-16)/36 )); r=$(( r==0?0: r*40 + 55 ))
        printf 'dec= %3s color= #%02x%02x%02x\n' "$dec" "$r" "$g" "$b"
    else
        gray=$(( (dec-232)*10+8 ))
        printf 'dec= %3s  gray= #%02x%02x%02x\n' "$dec" "$gray" "$gray" "$gray"
    fi
}

#for i in $(seq 0 255); do
    #tohex ${i}
#done

