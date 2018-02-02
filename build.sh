#!/bin/sh

set -e
set -u

jflag=
jval=2

while getopts 'j:' OPTION
do
  case $OPTION in
  j)  jflag=1
          jval="$OPTARG"
          ;;
  ?)  printf "Usage: %s: [-j concurrency_level] (hint: your cores + 20%%)\n" $(basename $0) >&2
    exit 2
    ;;
  esac
done
shift $(($OPTIND - 1))

if [ "$jflag" ]
then
  if [ "$jval" ]
  then
    printf "Option -j specified (%d)\n" $jval
  fi
fi

cd `dirname $0`
ENV_ROOT=`pwd`
. ./env.source

#if you want a rebuild
#rm -rf "$BUILD_DIR" "$TARGET_DIR"
mkdir -p "$BUILD_DIR" "$TARGET_DIR" "$DOWNLOAD_DIR" "$BIN_DIR"

#download and extract package
download(){
  filename="$1"
  if [ ! -z "$2" ];then
    filename="$2"
  fi
  ../download.pl "$DOWNLOAD_DIR" "$1" "$filename" "$3" "$4"
  #disable uncompress
  CACHE_DIR="$DOWNLOAD_DIR" ../fetchurl "http://cache/$filename"
}

echo "#### FFmpeg static build ####"

#this is our working directory
cd $BUILD_DIR

download \
  "yasm-1.3.0.tar.gz" \
  "" \
  "fc9e586751ff789b34b1f21d572d96af" \
  "http://www.tortall.net/projects/yasm/releases/"

download \
  "last_x264.tar.bz2" \
  "" \
  "nil" \
  "http://download.videolan.org/pub/videolan/x264/snapshots/"

download \
  "x265_2.6.tar.gz" \
  "" \
  "nil" \
  "https://bitbucket.org/multicoreware/x265/downloads/"

download \
  "master" \
  "fdk-aac.tar.gz" \
  "nil" \
  "https://github.com/mstorsjo/fdk-aac/tarball"

download \
  "lame-3.100.tar.gz" \
  "" \
  "83e260acbe4389b54fe08e0bdbf7cddb" \
  "http://sources.openwrt.org/"

download \
  "ffmpeg-snapshot.tar.bz2" \
  "" \
  "nil" \
  "http://ffmpeg.org/releases/"

echo "*** Building yasm ***"
cd $BUILD_DIR/yasm*
./configure --prefix=$TARGET_DIR --bindir=$BIN_DIR
make -j $jval
make install

echo "*** Building x264 ***"
cd $BUILD_DIR/x264*
PATH="$BIN_DIR:$PATH" ./configure --prefix=$TARGET_DIR --enable-static --disable-shared --disable-opencl
PATH="$BIN_DIR:$PATH" make -j $jval
make install

echo "*** Building x265 ***"
cd $BUILD_DIR/x265*
cd build/linux
PATH="$BIN_DIR:$PATH" cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="$TARGET_DIR" -DENABLE_SHARED:bool=off ../../source
make -j $jval
make install

echo "*** Building fdk-aac ***"
cd $BUILD_DIR/mstorsjo-fdk-aac*
autoreconf -fiv
./configure --prefix=$TARGET_DIR --disable-shared
make -j $jval
make install

echo "*** Building mp3lame ***"
cd $BUILD_DIR/lame*
./configure --prefix=$TARGET_DIR --enable-nasm --disable-shared
make
make install

NPROC=1
if which nproc;then
	NPROC="`nproc`"
elif [ -f /proc/cpuinfo ];then
	NPROC="`grep -c ^processor /proc/cpuinfo`"
elif which sysctl;then
	NPROC="`sysctl -n hw.ncpu`"
fi

FFMPEG_EXTRA_LDFLAG=""

case "$OSTYPE" in
  #solaris*) echo "SOLARIS" ;;
  darwin*)  FFMPEG_EXTRA_LDFLAG="-framework CoreText" ;; 
  #linux*)   echo "LINUX" ;;
  #bsd*)     echo "BSD" ;;
  #msys*)    echo "WINDOWS" ;;
  #*)        echo "unknown: $OSTYPE" ;;
esac

# FFMpeg
echo "*** Building FFmpeg ***"
cd $BUILD_DIR/ffmpeg*
PATH="$BIN_DIR:$PATH" \
LDFLAGS="${LDFLAGS} -lstdc++" \
PKG_CONFIG_PATH="$TARGET_DIR/lib/pkgconfig" ./configure \
  --prefix="$TARGET_DIR" \
  --pkg-config-flags="--static" \
  --extra-cflags="-I$TARGET_DIR/include" \
  --extra-ldflags="-L$TARGET_DIR/lib $FFMPEG_EXTRA_LDFLAG" \
  --bindir="$BIN_DIR" \
  --enable-gpl \
  --enable-pthreads \
  --enable-libfdk-aac \
  --enable-libmp3lame \
  --disable-decoder=libvpx \
  --enable-libx264 \
  --enable-libx265 \
  --enable-avfilter \
  --enable-filters \
  --enable-nonfree \
  --enable-runtime-cpudetect \
  --arch=x86_64
PATH="$BIN_DIR:$PATH" make -j$NPROC
make install
make distclean
hash -r
