FROM debian:11
MAINTAINER 刘荣飞 <yes@noxue.com>

RUN sed -i 's/http:\/\/deb.debian.org/http:\/\/mirrors.aliyun.com/g' /etc/apt/sources.list


RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -yq install git

RUN git clone  -b v1.10.10  https://github.com/signalwire/freeswitch /usr/src/freeswitch
RUN git clone https://github.com/signalwire/libks /usr/src/libs/libks
RUN git clone https://github.com/freeswitch/sofia-sip /usr/src/libs/sofia-sip

RUN git clone https://github.com/freeswitch/spandsp /usr/src/libs/spandsp && cd /usr/src/libs/spandsp
RUN git clone https://github.com/signalwire/signalwire-c /usr/src/libs/signalwire-c

RUN DEBIAN_FRONTEND=noninteractive apt-get -yq install \
    build-essential cmake automake autoconf 'libtool-bin|libtool' pkg-config \
    libssl-dev zlib1g-dev libdb-dev unixodbc-dev libncurses5-dev libexpat1-dev libgdbm-dev bison erlang-dev libtpl-dev libtiff5-dev uuid-dev \
    libpcre3-dev libedit-dev libsqlite3-dev libcurl4-openssl-dev nasm \
    libogg-dev libspeex-dev libspeexdsp-dev \
    libldns-dev \
    python3-dev \
    libavformat-dev libswscale-dev libavresample-dev \
    liblua5.2-dev \
    libopus-dev \
    libpq-dev \
    libsndfile1-dev libflac-dev libogg-dev libvorbis-dev \
    libshout3-dev libmpg123-dev libmp3lame-dev

RUN cd /usr/src/libs/libks && cmake . -DCMAKE_INSTALL_PREFIX=/usr -DWITH_LIBBACKTRACE=1 && make install
RUN cd /usr/src/libs/sofia-sip && ./bootstrap.sh && ./configure CFLAGS="-g -ggdb" --with-pic --with-glib=no --without-doxygen --disable-stun --prefix=/usr && make -j`nproc --all` && make install
RUN cd /usr/src/libs/spandsp && git checkout e59ca8fb8b1591e626e6a12fdc60a2ebe83435ed && ./bootstrap.sh && ./configure CFLAGS="-g -ggdb" --with-pic --prefix=/usr && make -j`nproc --all` && make install
RUN cd /usr/src/libs/signalwire-c && PKG_CONFIG_PATH=/usr/lib/pkgconfig cmake . -DCMAKE_INSTALL_PREFIX=/usr && make install

# Enable modules xml_int/mod_xml_curl
RUN sed -i 's|#formats/mod_shout|formats/mod_shout|' /usr/src/freeswitch/build/modules.conf.in
RUN sed -i 's|#xml_int/mod_xml_curl|xml_int/mod_xml_curl|' /usr/src/freeswitch/build/modules.conf.in

# 禁用
RUN sed -i 's|applications/mod_sms|#applications/mod_sms|' /usr/src/freeswitch/build/modules.conf.in
RUN sed -i 's|formats/mod_vpx|#formats/mod_vpx|' /usr/src/freeswitch/build/modules.conf.in


RUN cd /usr/src/freeswitch && ./bootstrap.sh -j  && ./configure  && make  && make install


# Cleanup the image
RUN apt-get clean

# Uncomment to cleanup even more
RUN rm -rf /usr/src/*

#  把 /usr/local/freeswitch/bin/ 添加到 PATH
ENV PATH /usr/local/freeswitch/bin:$PATH

# 启动freeswitch
CMD ["freeswitch", "-u", "freeswitch", "-g", "freeswitch", "-nonat", "-ncwait"]
