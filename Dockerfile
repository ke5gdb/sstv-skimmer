FROM debian:bookworm-slim

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y libfftw3-dev libfftw3-bin ffmpeg \
   xvfb pulseaudio build-essential git libsamplerate0-dev alsa-utils \
   python3 python3-pip cmake portaudio19-dev python3-dev python3-opencv \
   alsa-utils rtl-sdr \
   # # start ka9q-radio
   # avahi-utils build-essential make gcc libairspy-dev  \
   # libairspyhf-dev libavahi-client-dev libbsd-dev libhackrf-dev \
   # libiniparser-dev libncurses5-dev libopus-dev librtlsdr-dev libusb-1.0-0-dev \
   # libusb-dev libasound2-dev uuid-dev rsync libogg-dev libliquid-dev libnss-mdns \
   # # end ka9q-radio
   # start slowrx
   libgd-dev && \
   rm -rf /var/lib/apt/lists/*

# spy server
RUN git clone https://github.com/miweber67/spyserver_client.git && cd spyserver_client && make && cp ss_client /usr/bin/ss_iq
#csdr
RUN cd / && git clone https://github.com/jketterl/csdr.git && cd csdr && git checkout master && mkdir -p build && cd build && cmake .. && make && make install && ldconfig
# # ka9q-radio -- no ka9q radio until we can resolve dbus conflicts
# RUN cd / && git clone https://github.com/ka9q/ka9q-radio.git && cd ka9q-radio && make -f Makefile.linux pcmcat tune && cp pcmcat /usr/bin/pcmcat && cp tune /usr/bin/tune
# RUN sed -i -e 's/files dns/files mdns4_minimal [NOTFOUND=return] dns/g' /etc/nsswitch.conf
# python dependencies
RUN pip3 install --break-system-packages Mastodon.py discord.py watchdog soundmeter requests 

#RUN git clone https://github.com/ke5gdb/slowrx.git && cd slowrx && git checkout slowrx-daemon && make slowrxd && cp slowrxd /usr/bin/ 
COPY slowrx/ /slowrx/ 
RUN cd /slowrx/ && make slowrxd && cp slowrxd /usr/bin/ 

#pulse server requiremeent
RUN adduser root pulse-access

RUN ln -sf /dev/stdout /upload.log

# poster script
COPY poster.py /poster.py

#copy monitor scripts
COPY shutdown.sh /shutdown.sh
RUN chmod a+x /shutdown.sh

# startup script
COPY run.sh /run.sh
RUN chmod a+x /run.sh

# forking post script
COPY slowrx_post.sh /slowrx_post.sh
RUN chmod a+x /slowrx_post.sh

ENTRYPOINT ["/bin/sh", "-c", "/run.sh"]
VOLUME /images