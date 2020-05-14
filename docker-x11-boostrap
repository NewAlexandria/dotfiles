brew install socat
brew cask install xquartz

xhost +

xquartz gui > preferences > privacy > allow both

socat TCP-LISTEN:6000,reuseaddr,fork UNIX-CLIENT:\"$DISPLAY\"

docker run -it --rm -v /tmp/.X11-unix:/tmp/.X11-unix -e DISPLAY=host.docker.internal:0 debian:stretch bash


docker build -t eclp .

with:

## Dockerfile 

FROM debian:stretch

RUN apt update
RUN apt install -y eclipse-cdt eclipse-cdt-launch-remote

# https://github.com/osrf/docker_images/issues/21
ENV QT_X11_NO_MITSHM=1
RUN groupadd -r sgug && useradd --no-log-init -r -g sgug sgug
RUN mkdir /home/sgug
RUN chown -R sgug:sgug /home/sgug
WORKDIR /home/sgug
USER sgug

CMD '/usr/bin/eclipse'


