#!/bin/bash
# Dockerfile voxbone-workshop
# https://github.com/voxbone-workshop/janus_gateway
# Thu Dec 13 12:39:03 -02 2018
DIR="/vagrant"

### build tools ###
apt-get update && apt-get install -y \
	build-essential \
	autoconf \
	automake \
	cmake

### Utils ###
apt-get update && apt-get install -y \
	vim \
	curl \
	psmisc \
	nano \
	git \
	wget \
	unzip

### Janus ###
apt-get update && apt-get install -y \
	libmicrohttpd-dev \
	libjansson-dev \
	libglib2.0-dev \
	libevent-dev \
	libtool \
	gengetopt \
	libssl-dev \
	openssl \
        libconfig-dev \
        gtk-doc-tools \
	libcurl4-openssl-dev

### Build libnice
cd $DIR && wget https://nice.freedesktop.org/releases/libnice-0.1.16.tar.gz && \
	tar xvf libnice-0.1.16.tar.gz && \
	cd libnice-0.1.16 && \
	./configure --prefix=$DIR/usr && \
	make && \
	make install && \
	rm -rf $DIR/libnice-0.1.16*

### Build libwebsockets
cd $DIR && git clone https://github.com/warmcat/libwebsockets.git && \
	cd libwebsockets && \
	git checkout v2.0.2 && \
	mkdir build && \
	cd build && \
	cmake -DCMAKE_INSTALL_PREFIX:PATH=$DIR/usr .. && \
	make && \
	make install && \
	rm -rf $DIR/libwebsockets*

### Build libsrtp
cd $DIR && wget https://github.com/cisco/libsrtp/archive/v2.0.0.tar.gz -O libsrtp-2.0.0.tar.gz && \
	tar xfv libsrtp-2.0.0.tar.gz && \
	cd libsrtp-2.0.0 && \
	./configure --prefix=$DIR/usr --enable-openssl && \
	make shared_library && \
	make install && \
	rm -rf $DIR/libsrtp-2.0.0*

### Build sofia-sip
cd $DIR && wget http://conf.meetecho.com/sofiasip/sofia-sip-1.12.11.tar.gz && \
	tar xfv sofia-sip-1.12.11.tar.gz && \
	cd sofia-sip-1.12.11 && \
	wget http://conf.meetecho.com/sofiasip/0001-fix-undefined-behaviour.patch && \
	wget http://conf.meetecho.com/sofiasip/sofiasip-semicolon-authfix.diff && \
	patch -p1 -u < 0001-fix-undefined-behaviour.patch && \
	patch -p1 -u < sofiasip-semicolon-authfix.diff && \
	./configure --prefix=$DIR/usr && \
	make && \
	make install && \
	rm -rf $DIR/sofia-sip-1.12.11*

### Copy libs to build janus
cd $DIR && cp -pvr $DIR/usr/* /usr/

### Build janus gateway
cd $DIR && git clone https://github.com/meetecho/janus-gateway.git && \
	cd janus-gateway && \
	# Issue Janus, debug memory
	# https://github.com/meetecho/janus-gateway/issues/1808
	sed -i 's|//~ #define REFCOUNT_DEBUG|#define REFCOUNT_DEBUG|g' refcount.h && \
	./autogen.sh && \
        # Enable code dump janus
        #export CFLAGS="-fsanitize=address -fno-omit-frame-pointer" && \
        #export LDFLAGS="-lasan" && \
	./configure \
		--prefix=/opt/janus \
		--disable-docs \
		--disable-plugin-videoroom \
		--disable-plugin-streaming \
		--disable-plugin-audiobridge \
		--disable-plugin-textroom \
		--disable-plugin-recordplay \
		--disable-plugin-videocall \
		--disable-plugin-voicemail \
		--disable-rabbitmq \
		--disable-mqtt \
		--disable-unix-sockets \
		--disable-data-channels && \
	make && \
	make install && \
	make configs && \
	rm -rf $DIR/janus-gateway*

### Create deb package janus-webrtc-gateway
cd $DIR
apt-get install ruby ruby-dev rubygems build-essential -y
gem install --no-ri --no-rdoc fpm

NAME=janus-webrtc-gateway
VERSION=4
MINOR=1

mkdir $DIR/opt && \
	cp -pvr /opt/janus $DIR/opt/

fpm -s dir -t deb -n $NAME -v $MINOR-$VERSION \
	-d "libmicrohttpd-dev" \
	-d "libjansson-dev" \
	-d "libglib2.0-dev" \
	-d "libevent-dev" \
	-d "libtool" \
	-d "gengetopt" \
	-d "libssl-dev" \
	-d "openssl" \
	-d "libconfig-dev" \
	-d "gtk-doc-tools" \
	-d "libcurl4-openssl-dev" \
	--config-files /opt/janus/etc/janus \
	--after-install $DIR/post-install \
	--deb-systemd $DIR/etc/systemd/system/janus.service \
	--description "Janus Webrtc Gateway" \
	--maintainer "lcarneirofreitas@gmail.com" \
	etc opt usr

### Cleaning ###
cd $DIR && rm -rf usr opt && \
apt-get clean && apt-get autoclean && apt-get autoremove -y

