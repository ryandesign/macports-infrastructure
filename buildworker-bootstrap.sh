#!/bin/bash

set -euo pipefail

if [ "$(id -u)" != 0 ]; then
  echo "$0: must run this script as root" 1>&2
  exit 1
fi

UI_PREFIX="---> "
PREFIX=/opt/bblocal
SOURCE_URL=https://svn.macports.org/repository/macports/trunk/base
SOURCE_DIR=/opt/macports-base
EXTRA_PORTS_URL=https://github.com/ryandesign/macports-infrastructure
EXTRA_PORTS_WC=/opt/macports-infrastructure
EXTRA_PORTS_DIR="$EXTRA_PORTS_WC/ports"

if [ "$PREFIX" = "/opt/local" ]; then
  APPLICATIONS_DIR="/Applications/MacPorts"
else
  APPLICATIONS_DIR="$PREFIX/Applications"
fi

USER="$(id -n -u)"
GROUP="$(id -n -g)"

ORIG_USER="$(logname)"
ORIG_GROUP="$(id -n -g $ORIG_USER)"

if [ ! -x $PREFIX/bin/port ]; then
  JOBS="$(sysctl -n hw.activecpu)"

  export MACOSX_DEPLOYMENT_TARGET="$(sw_vers -productVersion | cut -d . -f 1-2)"

  export PATH="/bin:/sbin:/usr/bin:/usr/sbin"

  export GREP_OPTIONS=""

  if [ ! -d "$SOURCE_DIR" ]; then
    echo "$UI_PREFIX Checking out MacPorts source code"
    mkdir -p "$SOURCE_DIR"
    [ -d "$SOURCE_DIR" ] || exit 1
    svn co "$SOURCE_URL" "$SOURCE_DIR"
  else
    echo "$UI_PREFIX Updating MacPorts source code"
    svn up "$SOURCE_DIR"
  fi

  cd $SOURCE_DIR

  echo "$UI_PREFIX Configuring MacPorts"
  ./configure \
  --prefix=$PREFIX \
  --enable-readline \
  --with-applications-dir=$APPLICATIONS_DIR \
  --with-frameworks-dir=$PREFIX/Library/Frameworks \
  --with-install-group="$GROUP" \
  --with-install-user="$USER" \
  --with-macports-user=macports

  echo "$UI_PREFIX Building MacPorts"
  make -j$JOBS

  echo "$UI_PREFIX Installing MacPorts"
  make install

  #echo "$UI_PREFIX Testing MacPorts"
  #make test

  echo "$UI_PREFIX Cleaning MacPorts"
  make distclean
fi

echo "$UI_PREFIX Updating MacPorts"
sudo $PREFIX/bin/port selfupdate

if [ "$PREFIX" != "/opt/local" ]; then
  if [ ! -d $PREFIX/var/macports/distfiles ]; then
    echo "$UI_PREFIX Linking distfiles to main distfiles"
    mkdir -p $PREFIX/var/macports
    [ -d $PREFIX/var/macports ] || exit 1
    mkdir -p /opt/local/var/macports/distfiles
    [ -d /opt/local/var/macports ] || exit 1
    ln -s /opt/local/var/macports/distfiles $PREFIX/var/macports/distfiles
  fi
fi

if [ ! -x $PREFIX/bin/git ]; then
  echo "$UI_PREFIX Installing git"
  sudo $PREFIX/bin/port -N install git
fi

if [ ! -d "$EXTRA_PORTS_WC" ]; then
  echo "$UI_PREFIX Cloning $EXTRA_PORTS_URL to $EXTRA_PORTS_WC"
  $PREFIX/bin/git clone "$EXTRA_PORTS_URL" "$EXTRA_PORTS_WC"
  [ -d "$EXTRA_PORTS_WC" ] || exit 1
else
  echo "$UI_PREFIX Updating $EXTRA_PORTS_WC"
  $PREFIX/bin/git -C "$EXTRA_PORTS_WC" pull
fi

if ! grep -q "file://$EXTRA_PORTS_DIR" $PREFIX/etc/macports/sources.conf; then
  echo "$UI_PREFIX Adding $EXTRA_PORTS_DIR to sources.conf"
  echo "file://$EXTRA_PORTS_DIR" >> $PREFIX/etc/macports/sources.conf
fi

PROFILE="$HOME/.profile"

#if ! echo $PATH | tr : "\n" | grep -q "^$PREFIX/bin$"; then
if [ ! -f "$PROFILE" ]; then
  touch "$PROFILE"
  chown "$ORIG_USER":"$ORIG_GROUP" "$PROFILE"
fi
if ! grep -q "$PREFIX/bin:$PREFIX/sbin" "$PROFILE"; then
  echo "$UI_PREFIX Setting up profile"
  echo "export PATH=$PREFIX/bin:$PREFIX/sbin:\$PATH" >> "$PROFILE"
fi
