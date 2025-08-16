#!/usr/bin/sh

alias pr="qlmanage -p "

function ratio() {
  a=$(identify -format "w=%w;h=%h" $1)
  eval $a

  if [ "$w" -ge "$h" ]; then
      echo 'landscape'
  else
      echo 'portrait'
  fi
}


### ==== Converters =======================================

# scale video
# ffmpeg -i input.avi -filter:v scale=720:-1 -c:a copy output.mkv

function video2agif() {
  INPUT  = $1
  OUTPUT = $1.gif
  SCALE  = ${2?"240"}
  FPS    = ${3?"10"}

  ffmpeg -i $INPUT -vf scale=$SCALE:-1 -r $FPS -f image2pipe -vcodec ppm - | \
  convert -delay 0 -loop 0 - gif:- | \
  convert -layers Optimize - $OUTPUT
}

# converts most sources, actually
# cannot convert gif->gif
# source: https://gist.github.com/ndarville/10010916
function gif2webm() {
  if [ $# -eq 0 ]
    then
      echo "usage: file-name [format] [bitrate 1000] [crf 12]"
    else
      FORMAT=${2:-'webm'}
      BITRATE=${3:-'1000'}
      RATE_SZ='K'
      CRF=${4:-'12'}
      ffmpeg -i "$1" -c:v libvpx -crf $CRF -b:v $BITRATE$RATE_SZ  -auto-alt-ref 0 "$1.$FORMAT"
  fi
}

function sliceWebm() {
  # $1 example: input.webm
  # $2 example: output.mpg
  # $3 example: 00:00:06
  # $4 example: 00:00:06
  ffmpeg -ss $3 -i $1 -t $4 -c:v mpeg2video -c:a mp2 $2
}


function gifcomposite() {
  HT=${4:-'200'}
  HT=${5:-'200'}
  convert $1 null: \( $2 -coalesce -resize $4x$5! \) -gravity Center -layers composite $3
}

function webm2anim() {
  if [ $# -eq 0 ]
    then
      echo "usage: file-name [format] [bitrate 1000] [crf 12]"
    else
      FORMAT=${2:-'webm'}
      BITRATE=${3:-'1000'}
      RATE_SZ='K'
      CRF=${4:-'12'}
      ffmpeg -i "$1" -crf $CRF -b:v $BITRATE$RATE_SZ  "$1.$FORMAT"
  fi
}

function video4aac() {
   ffmpeg -i "$1" -acodec aac -vcodec copy "$2"
}

function hdr2sdr() {
  video=$1
  format=".SDR.mkv"

  echo "$video"
  echo "${video//.mkv/$format}"

  if [[ -f "$video" ]]; then
      ffmpeg -i "$video" -vf \
          "zscale=t=linear:npl=100,format=gbrpf32le,zscale=p=bt709,tonemap=tonemap=hable:desat=0,zscale=t=bt709:m=bt709:r=tv,format=yuv420p" \
          -c:v libx265 -crf 18 -preset ultrafast -map 0 -c:s copy "${video//.mkv/$format}"
  else
      echo "File not found"
  fi
}

alias drawio="/Applications/draw.io.app/Contents/MacOS/draw.io"
function drawio2png() {
  /Applications/draw.io.app/Contents/MacOS/draw.io -x -f png --scale 2.5 $1
}

### ==== Audio =======================================

function ytmp3() {
  if [ $# -eq 0 ]
    then
      echo "usage: media-url [audio-format]"
    else
      FORMAT=${2:-'mp3'}
      yt-dlp $1 -x --audio-format "$FORMAT"
  fi
}

function audiospeed() {
  splitrate=$(echo $1 | ruby -e 'puts 1 / readline.strip.to_f')
  namebase=$(echo $2 | ruby -e 'puts readline.split(".")[0..-2].join(".")')
  ffmpeg -i "$splitrate" -filter_complex "[0:v]setpts=0.5*PTS[v];[0:a]atempo=2[a]" -map "[v]" -map "[a]" "$namebase-$1x.mp3"
}

function mp3shorten() {
   ffmpeg -i  $1 -ss 0 -to 18  -acodec copy $2
}

function mp32ringtone() {
  ffmpeg -i $1 -c:a libfdk_aac -f ipod -b:a 96k $2
}

### ==== Getters  =======================================

function rumble-dl() {
 [ -n "$1" ] && for s in $*
  do url=`wget -O- $s | sed -n -E 's/^.*embedUrl...([^"]+).*$/\1/p'`
  [ -n "$url" ] && yt-dlp $url
 done
}

# /Users/zak/.dotfiles/utils/soundcloud-artist-getter.rb
