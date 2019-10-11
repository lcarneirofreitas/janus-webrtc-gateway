# Dockerfile voxbone-workshop
# https://github.com/voxbone-workshop/janus_gateway
# Thu Dec 13 12:39:03 -02 2018

DIR=$(pwd)

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

### Build janus gateway
cd $DIR && git clone https://github.com/meetecho/janus-gateway.git && \
	cd janus-gateway && \
	./autogen.sh && \
        # enable code dump janus
        export CFLAGS="-fsanitize=address -fno-omit-frame-pointer" && \
        export LDFLAGS="-lasan" && \
	export LD_LIBRARY_PATH="$DIR/usr" && \
	export LD_RUN_PATH="$DIR/usr" && \
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

### Cleaning ###
### apt-get clean && apt-get autoclean && apt-get autoremove -y

### Create deb package janus-webrtc-gateway
cd $DIR
apt-get install ruby ruby-dev rubygems build-essential -y
gem install --no-ri --no-rdoc fpm

NAME=janus-webrtc-gateway
VERSION=1
MINOR=12

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
	--description "Janus Webrtc Gateway Teravoz" \
	--maintainer "leandro.freitas@teravoz.com.br" \
	etc opt usr

