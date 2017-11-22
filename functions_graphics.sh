#!/usr/bin/sh

function ratio() {
  a=$(identify -format "w=%w;h=%h" $1)
  eval $a

  if [ "$w" -ge "$h" ]; then
      echo 'landscape'
  else
      echo 'portrait'
  fi
}

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
  BITRATE=${3:='1000'}
  RATE_SZ='K'
  CRF=${4:='12'}
  ffmpeg -i "$1" $2 -c:v libvpx -crf $CRF -b:v $BITRATE$RATE_SZ  -auto-alt-ref 0 "$1.webm"
}

function mp3shorten() {
   ffmpeg -i  $1 -ss 0 -to 18  -acodec copy $2
}

function mp32ringtone() {
  ffmpeg -i $1 -c:a libfdk_aac -f ipod -b:a 96k $2
}

