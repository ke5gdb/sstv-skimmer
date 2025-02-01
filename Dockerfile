FROM ubuntu:21.04

ARG DEBIAN_FRONTEND=noninteractive
ARG QSSTV_CONFIG=qsstv_9.0.conf

RUN sed -i -re 's/ports.ubuntu.com\/ubuntu-ports|security.ubuntu.com\/ubuntu-ports|archive.ubuntu.com\/ubuntu|security.ubuntu.com\/ubuntu/old-releases.ubuntu.com\/ubuntu/g' /etc/apt/sources.list

RUN apt-get update && apt-get install -y libfftw3-dev libfftw3-3 ffmpeg \
xvfb qsstv pulseaudio build-essential git libsamplerate0-dev alsa-utils \
xvfb python3 python3-pip cmake portaudio19-dev python-dev python3-opencv \
alsa-utils rtl-sdr && rm -rf /var/lib/apt/lists/*

# spy server
RUN git clone https://github.com/miweber67/spyserver_client.git && cd spyserver_client && make && cp ss_client /usr/bin/ss_iq
#csdr
RUN cd / && git clone https://github.com/jketterl/csdr.git && cd csdr && git checkout master && mkdir -p build && cd build && cmake .. && make && make install && ldconfig
# python dependencies
RUN pip3 install Mastodon.py discord.py watchdog soundmeter requests
#pulse server requiremeent
RUN adduser root pulse-access

# qsstv config
RUN mkdir -p /root/.config/ON4QZ/
COPY ${QSSTV_CONFIG} /root/.config/ON4QZ/qsstv_9.0.conf

# poster script
COPY poster.py /poster.py

#copy monitor scripts
COPY shutdown.sh /shutdown.sh
RUN chmod a+x /shutdown.sh

# startup script
COPY run.sh /run.sh
RUN chmod a+x /run.sh

ENTRYPOINT ["/bin/sh", "-c", "/run.sh"]
VOLUME /images
VOLUME /drm