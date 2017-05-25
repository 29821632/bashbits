#!/bin/bash

# Build latest version of curl from source. Tested in *buntu distros which use GnuTLS for the packaged curl
# Requires following packages:  nghttp2 libnghttp2-dev libgnutls-dev libidn2-0 libidn2-0-dev
# Ben Bradley 2017. https://github.com/benbradley


cd /usr/local/src || exit 1

# CRAWL PAGE, GET LATEST VERSION
DLFILE=$(curl -s https://curl.haxx.se/download/ | grep -o ">curl-7\.[0-9]\{1,2\}\.[0-9]\{1,2\}\.tar\.bz2<" | tr -d '<>' | sort | tail -n1)

# STRIP FILE EXT
CURLVER=${DLFILE%.tar.bz2}

echo "*** Found latest version '$DLFILE'. Downloading..."
if [ ! -f "$DLFILE" ]; then
	wget "https://curl.haxx.se/download/$DLFILE"
fi


DLFILESIZE=$(du -k "$DLFILE" | cut -f1)

if [ -f "$DLFILE" ] && [ "$DLFILESIZE" -gt 1000 ]; then

	echo "*** Download OK. Extracting..."
	tar -xjf "$DLFILE"

	if [ $? -ne 0 ]; then
		echo "ERROR: Extract failed."
		exit 1
	fi
else
	exit 1
fi

cd "$CURLVER" || exit 1
chown -R root: .

# BUILD
./configure --with-nghttp2 --with-gnutls --disable-shared --prefix=/usr/local
make && make install
