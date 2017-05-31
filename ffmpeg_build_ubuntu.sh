#!/bin/bash

# FFmpeg build script for Ubuntu based distributions.
# Tested with Ubuntu 14.04
# Ben Bradley 2013. https://github.com/benbradley

echo ""
echo "FFmpeg build script for Ubuntu based distributions"
echo "Based on: https://trac.ffmpeg.org/wiki/CompilationGuide/Ubuntu"
echo "  as of April 18, 2017"
echo "---"
echo ""

read -r -p "Build directory [/usr/local/src/ffmpeg_build] " FFBUILDDIR
if [ -z "$FFBUILDDIR" ]; then
  FFBUILDDIR='/usr/local/src/ffmpeg_build'
fi

read -r -p "Source directory [/usr/local/src/ffmpeg_src] " FFSOURCEDIR
if [ -z "$FFSOURCEDIR" ]; then
  FFSOURCEDIR='/usr/local/src/ffmpeg_src'
fi

read -r -p "Bin output directory [/usr/local/bin] " FFBINDIR
if [ -z "$FFBINDIR" ]; then
  FFBINDIR='/usr/local/bin'
fi


mkdir "$FFBUILDDIR" > /dev/null 2>&1
if [ ! -d "$FFBUILDDIR" ]; then
  echo "Build directory '$FFBUILDDIR' could not be created"
  exit 1
fi


mkdir "$FFSOURCEDIR" > /dev/null 2>&1
if [ ! -d "$FFSOURCEDIR" ]; then
  echo "Source directory '$FFSOURCEDIR' could not be created"
  exit 1
fi


mkdir "$FFBINDIR" > /dev/null 2>&1
if [ ! -d "$FFBINDIR" ]; then
  echo "Bin output directory '$FFBINDIR' could not be created"
  exit 1
fi


cd "$FFSOURCEDIR" || exit 1


# INSTALL DEPS
sudo apt-get update
if [ $? -ne 0 ]; then
  exit 1
fi

sudo apt-get -y install autoconf automake build-essential libass-dev libfreetype6-dev \
  libsdl2-dev libtheora-dev libtool libva-dev libvdpau-dev libvorbis-dev libxcb1-dev libxcb-shm0-dev \
  libxcb-xfixes0-dev pkg-config texinfo zlib1g-dev
if [ $? -ne 0 ]; then
  exit 1
fi

# INSTALL YASM
cd "$FFSOURCEDIR"
wget http://www.tortall.net/projects/yasm/releases/yasm-1.3.0.tar.gz
tar xzvf yasm-1.3.0.tar.gz
cd yasm-1.3.0
./configure --prefix="FFBUILDDIR" --bindir="$FFBINDIR"
make
make install
. ~/.bash_profile

# INSTALL libx264
cd "$FFSOURCEDIR"
wget http://download.videolan.org/pub/x264/snapshots/last_x264.tar.bz2
tar xjvf last_x264.tar.bz2
cd x264-snapshot*
PATH="$FFBINDIR:$PATH" ./configure --prefix="$FFBUILDDIR" --bindir="$FFBINDIR" --enable-static --disable-opencl
PATH="$FFBINDIR:$PATH" make
make install

# INSTALL libx265
cd "$FFSOURCEDIR"
hg clone https://bitbucket.org/multicoreware/x265
cd "$FFSOURCEDIR/x265/build/linux"
PATH="$FFBINDIR:$PATH" cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="$FFBUILDDIR" -DENABLE_SHARED:bool=off ../../source
make
make install



# INSTALL libfdk-aac
cd "$FFSOURCEDIR"
wget -O fdk-aac.tar.gz https://github.com/mstorsjo/fdk-aac/tarball/master
tar xzvf fdk-aac.tar.gz
cd mstorsjo-fdk-aac*
autoreconf -fiv
./configure --prefix="$FFBUILDDIR" --disable-shared
make
make install

# INSTALL libmp3lame
sudo apt-get install nasm
cd "$FFSOURCEDIR"
wget http://downloads.sourceforge.net/project/lame/lame/3.99/lame-3.99.5.tar.gz
tar xzvf lame-3.99.5.tar.gz
cd lame-3.99.5
./configure --prefix="$FFBUILDDIR" --enable-nasm --disable-shared
make
make install

# INSTALL libopus
cd "$FFSOURCEDIR"
wget http://downloads.xiph.org/releases/opus/opus-1.1.4.tar.gz
tar xzvf opus-1.1.4.tar.gz
cd opus-1.1.4
./configure --prefix="$FFBUILDDIR" --disable-shared
make
make install

# INSTALL libvpx
cd "$FFSOURCEDIR"
wget http://storage.googleapis.com/downloads.webmproject.org/releases/webm/libvpx-1.6.1.tar.bz2
tar xjvf libvpx-1.6.1.tar.bz2
cd libvpx-1.6.1
PATH="$FFBINDIR" ./configure --prefix="$FFBUILDDIR" --disable-examples --disable-unit-tests
PATH="$FFBINDIR" make
make install

# INSTALL ffmpeg
cd "$FFSOURCEDIR"
wget http://ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2
tar xjvf ffmpeg-snapshot.tar.bz2
cd ffmpeg

PATH="$FFBINDIR:$PATH" PKG_CONFIG_PATH="$FFBUILDDIR/lib/pkgconfig" ./configure \
  --prefix="$$FFBUILDDIR" \
  --extra-cflags="-I$$FFBUILDDIR/include" \
  --extra-ldflags="-L$$FFBUILDDIR/lib" \
  --bindir="$FFBINDIR" \
  --pkg-config-flags="--static" \
  --enable-gpl \
  --enable-libass \
  --enable-libfdk-aac \
  --enable-libfreetype \
  --enable-libmp3lame \
  --enable-libopus \
  --enable-libtheora \
  --enable-libvorbis \
  --enable-libvpx \
  --enable-libx264 \
  --enable-libx265 \
  --enable-nonfree
PATH="$FFBINDIR:$PATH" make
make install
hash -r