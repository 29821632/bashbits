#!/bin/bash

# FFmpeg build script for EL/Fedora based distributions.
# Tested with RHEL 6+, Fedora 22+
# Ben Bradley 2013. https://github.com/benbradley

echo ""
echo "FFmpeg build script for EL/Fedora based distributions"
echo "Based on: https://trac.ffmpeg.org/wiki/CentosCompilationGuide"
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
yum install -y autoconf automake gcc gcc-c++ git libtool make nasm pkgconfig zlib-devel
if [ $? -ne 0 ]; then
	exit 1
fi


curl -O http://www.tortall.net/projects/yasm/releases/yasm-1.2.0.tar.gz
tar xzvf yasm-1.2.0.tar.gz
cd yasm-1.2.0
./configure --prefix="$FFBUILDDIR" --bindir="$FFBINDIR"
make
make install
make distclean
. ~/.bash_profile

cd "$FFSOURCEDIR"
git clone --depth 1 git://git.videolan.org/x264
cd x264
./configure --prefix="$FFBUILDDIR" --bindir="$FFBINDIR" --enable-static
make
make install
make distclean

cd "$FFSOURCEDIR"
git clone --depth 1 git://github.com/mstorsjo/fdk-aac.git
cd fdk-aac
autoreconf -fiv
./configure --prefix="$FFBUILDDIR" --disable-shared
make
make install
make distclean

cd "$FFSOURCEDIR"
curl -L -O http://downloads.sourceforge.net/project/lame/lame/3.99/lame-3.99.5.tar.gz
tar xzvf lame-3.99.5.tar.gz
cd lame-3.99.5
./configure --prefix="$FFBUILDDIR" --bindir="$FFBINDIR" --disable-shared --enable-nasm
make
make install
make distclean

cd "$FFSOURCEDIR"
curl -O http://downloads.xiph.org/releases/opus/opus-1.0.3.tar.gz
tar xzvf opus-1.0.3.tar.gz
cd opus-1.0.3
./configure --prefix="$FFBUILDDIR" --disable-shared
make
make install
make distclean

cd "$FFSOURCEDIR"
curl -O http://downloads.xiph.org/releases/ogg/libogg-1.3.1.tar.gz
tar xzvf libogg-1.3.1.tar.gz
cd libogg-1.3.1
./configure --prefix="$FFBUILDDIR" --disable-shared
make
make install
make distclean

cd "$FFSOURCEDIR"
curl -O http://downloads.xiph.org/releases/vorbis/libvorbis-1.3.3.tar.gz
tar xzvf libvorbis-1.3.3.tar.gz
cd libvorbis-1.3.3
./configure --prefix="$FFBUILDDIR" --with-ogg="$FFBUILDDIR" --disable-shared
make
make install
make distclean

cd "$FFSOURCEDIR"
git clone --depth 1 https://chromium.googlesource.com/webm/libvpx
cd libvpx
./configure --prefix="$FFBUILDDIR" --disable-examples
make
make install
make clean

cd "$FFSOURCEDIR"
curl -O http://downloads.xiph.org/releases/theora/libtheora-1.1.1.tar.gz
tar xzvf libtheora-1.1.1.tar.gz
cd libtheora-1.1.1
./configure --prefix="$FFBUILDDIR" --with-ogg="$FFBUILDDIR" --disable-examples --disable-shared --disable-sdltest --disable-vorbistest
make
make install
make distclean

yum -y install freetype-devel speex-devel

cd "$FFSOURCEDIR"
git clone --depth 1 git://source.ffmpeg.org/ffmpeg
cd ffmpeg
PKG_CONFIG_PATH="$FFBUILDDIR/lib/pkgconfig"
export PKG_CONFIG_PATH
./configure --prefix="$FFBUILDDIR" --extra-cflags="-I$FFBUILDDIR/include" --extra-ldflags="-L$FFBUILDDIR/lib" --bindir="$FFBINDIR" --extra-libs="-ldl" --enable-gpl --enable-nonfree --enable-libfdk_aac --enable-libmp3lame --enable-libopus --enable-libvorbis --enable-libvpx --enable-libx264 --enable-libfreetype --enable-libspeex --enable-libtheora
make
make install
make distclean
hash -r
. ~/.bash_profile

cd "$FFSOURCEDIR/ffmpeg/tools"
make qt-faststart
cp qt-faststart /usr/bin
ldconfig
cd
