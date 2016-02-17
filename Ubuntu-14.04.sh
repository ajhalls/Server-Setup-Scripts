##### Setting up a new server #####
# Should already have a LAMP stack installed performed during basic install.
# Also update and upgrade system.
# Will setup basic benchmarking / development tools, Node, FFMPEG, and other random things 
# Takes a while, just start it and go to lunch

apt-get -y install lynx-cur default-jre atop iotop iftop apache2-utils

# Node
wget http://nodejs.org/dist/v0.10.30/node-v0.10.30.tar.gz
tar xzvf node-v* && cd node-v*
yum -y install gcc gcc-c++
./configure
make
make install

##### FFMPEG Install Script for Ubuntu 14.04 #####
apt-get -y --force-yes install autoconf automake build-essential libass-dev libfreetype6-dev libsdl1.2-dev libtheora-dev libtool libva-dev libvdpau-dev libvorbis-dev libxcb1-dev libxcb-shm0-dev libxcb-xfixes0-dev pkg-config texinfo zlib1g-dev

mkdir ~/ffmpeg_sources

apt-get -y install yasm libx264-dev libmp3lame-dev libopus-dev cmake mercurial

# libx265 
cd ~/ffmpeg_sources
hg clone https://bitbucket.org/multicoreware/x265
cd ~/ffmpeg_sources/x265/build/linux
PATH="$HOME/bin:$PATH" cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="$HOME/ffmpeg_build" -DENABLE_SHARED:bool=off ../../source
make
make install
make distclean

# libfdk-aac
cd ~/ffmpeg_sources
wget -O fdk-aac.tar.gz https://github.com/mstorsjo/fdk-aac/tarball/master
tar xzvf fdk-aac.tar.gz
cd mstorsjo-fdk-aac*
autoreconf -fiv
./configure --prefix="$HOME/ffmpeg_build" --disable-shared
make
make install
make distclean

# libvpx
cd ~/ffmpeg_sources
wget http://storage.googleapis.com/downloads.webmproject.org/releases/webm/libvpx-1.5.0.tar.bz2
tar xjvf libvpx-1.5.0.tar.bz2
cd libvpx-1.5.0
PATH="$HOME/bin:$PATH" ./configure --prefix="$HOME/ffmpeg_build" --disable-examples --disable-unit-tests
PATH="$HOME/bin:$PATH" make
make install
make clean

# install Vidstab
cd ~/ffmpeg_sources
git clone --depth 1 https://github.com/georgmartius/vid.stab.git
cd vid.stab
cmake -DCMAKE_INSTALL_PREFIX:PATH="$HOME/ffmpeg_build"
make
make install

# FFMPEG Final Build
cd ~/ffmpeg_sources
wget http://ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2
tar xjvf ffmpeg-snapshot.tar.bz2
cd ffmpeg
PATH="$HOME/bin:$PATH" PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig" ./configure \
  --prefix="$HOME/ffmpeg_build" \
  --pkg-config-flags="--static" \
  --extra-cflags="-I$HOME/ffmpeg_build/include" \
  --extra-ldflags="-L$HOME/ffmpeg_build/lib" \
  --bindir="$HOME/bin" \
  --enable-gpl \
  --enable-libvidstab \  
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
PATH="$HOME/bin:$PATH" make
make install
make distclean
hash -r

# Copy compiled files to global bin
cd ~/bin
mv * /usr/local/bin

####### End of FFMPEG Install #########


