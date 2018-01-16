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
  "lame-3.99.5.tar.gz" \
  "" \
  "84835b313d4a8b68f5349816d33e07ce" \
  "http://downloads.sourceforge.net/project/lame/lame/3.99"

download \
  "opus-1.1.tar.gz" \
  "" \
  "c5a8cf7c0b066759542bc4ca46817ac6" \
  "http://downloads.xiph.org/releases/opus"

download \
  "v1.5.0.tar.gz" \
  "" \
  "0c662bc7525afe281badb3175140d35c" \
  "https://github.com/webmproject/libvpx/archive/"

download \
  "freetype-2.7.tar.gz" \
  "" \
  "337139e5c7c5bd645fe130608e0fa8b5" \
  "http://download.savannah.gnu.org/releases/freetype/"

download \
  "fribidi-0.19.7.tar.bz2" \
  "" \
  "6c7e7cfdd39c908f7ac619351c1c5c23" \
  "http://fribidi.org/download/"

download \
  "libass-0.13.4.tar.gz" \
  "" \
  "158e242c1bd890866e95526910cb6873" \
  "https://github.com/libass/libass/releases/download/0.13.4/"

download \
  "libogg-1.3.1.tar.gz" \
  "" \
  "ba526cd8f4403a5d351a9efaa8608fbc" \
  "http://downloads.xiph.org/releases/ogg/"

download \
  "libvorbis-1.3.3.tar.gz" \
  "" \
  "6b1a36f0d72332fae5130688e65efe1f" \
  "http://downloads.xiph.org/releases/vorbis/"

download \
  "SDL-1.2.15.tar.gz" \
  "" \
  "9d96df8417572a2afb781a7c4c811a85" \
  "http://www.libsdl.org/release/"

download \
  "libtheora-1.1.1.tar.bz2" \
  "" \
  "292ab65cedd5021d6b7ddd117e07cd8e" \
  "http://downloads.xiph.org/releases/theora/"

download \
  "ffmpeg-3.4.1.tar.bz2" \
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

echo "*** Building opus ***"
cd $BUILD_DIR/opus*
./configure --prefix=$TARGET_DIR --disable-shared
make
make install

echo "*** Building freetype2 ***"
cd $BUILD_DIR/freetype-2*
./configure --prefix=$TARGET_DIR --disable-shared
make
make install

echo "*** Building fribidi ***"
cd $BUILD_DIR/fribidi*
./configure --prefix=$TARGET_DIR --disable-shared
make
make install

echo "*** Building libass ***"
cd $BUILD_DIR/libass*
./configure --prefix=$TARGET_DIR --disable-shared
make
make install

echo "*** Building libogg ***"
cd $BUILD_DIR/libogg*
./configure --prefix=$TARGET_DIR --disable-shared
make
make install

echo "*** Building libvorbis ***"
cd $BUILD_DIR/libvorbis*
./configure --prefix=$TARGET_DIR --disable-shared
make
make install

echo "*** Building SDL ***"
cd $BUILD_DIR/SDL-1*
case "$OSTYPE" in
  #solaris*) echo "SOLARIS" ;;
  darwin*)   patch -p1 <../../patches/sdl/sdl-1.2.15-macosx-compile.patch;; 
  #linux*)   echo "LINUX" ;;
  #bsd*)     echo "BSD" ;;
  #msys*)    echo "WINDOWS" ;;
  #*)        echo "unknown: $OSTYPE" ;;
esac
./configure --prefix=$TARGET_DIR --disable-shared
make
make install

echo "*** Building libtheora ***"
cd $BUILD_DIR/libtheora*
./configure --prefix=$TARGET_DIR --disable-shared
make
make install

echo "*** Building libvpx ***"
cd $BUILD_DIR/libvpx*
PATH="$BIN_DIR:$PATH" ./configure --prefix=$TARGET_DIR --disable-examples --disable-unit-tests
PATH="$BIN_DIR:$PATH" make -j $jval
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
  --enable-ffplay \
  --enable-ffserver \
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
PATH="$BIN_DIR:$PATH" make -j$NPROC
make install
make distclean
hash -r
