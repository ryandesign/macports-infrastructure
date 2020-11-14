#!/bin/bash

set -euo pipefail

if [ "$(id -u)" != 0 ]; then
  echo "$0: must run this script as root" 1>&2
  exit 1
fi

: "${TMPDIR:=/tmp}"

UI_PREFIX="---> "
PREFIX=/opt/bblocal
MACPORTS_VERSION=2.6.4
MACPORTS_BASENAME=MacPorts-"$MACPORTS_VERSION"
MACPORTS_FILENAME="$MACPORTS_BASENAME".tar.bz2
SOURCE_URL=http://distfiles.macports.org/MacPorts/"$MACPORTS_FILENAME"
SOURCE_FILE="$TMPDIR"/"$MACPORTS_FILENAME"
SOURCE_DIR="$TMPDIR"/"$MACPORTS_BASENAME"
EXTRA_PORTS_URL=https://github.com/ryandesign/macports-infrastructure
EXTRA_PORTS_WC=/opt/macports-infrastructure
EXTRA_PORTS_DIR="$EXTRA_PORTS_WC"/ports

if [ "$PREFIX" = "/opt/local" ]; then
  APPLICATIONS_DIR=/Applications/MacPorts
else
  APPLICATIONS_DIR="$PREFIX"/Applications
fi

USER=$(id -n -u)
GROUP=$(id -n -g)

ORIG_USER=$(logname)
ORIG_GROUP=$(id -n -g "$ORIG_USER")

if [ ! -x "$PREFIX"/bin/port ]; then
  JOBS=$(sysctl -n hw.activecpu)

  MACOSX_DEPLOYMENT_TARGET=$(sw_vers -productVersion | cut -d . -f 1-2)
  export MACOSX_DEPLOYMENT_TARGET

  export PATH=/bin:/sbin:/usr/bin:/usr/sbin

  export GREP_OPTIONS=

  if [ ! -d "$SOURCE_DIR" ]; then
    if [ ! -f "$SOURCE_FILE" ]; then
      echo "$UI_PREFIX Downloading MacPorts"
      curl -L -o "$SOURCE_FILE" "$SOURCE_URL"
    fi

    echo "$UI_PREFIX Extracting MacPorts"
    tar -C "$(dirname "$SOURCE_DIR")" -xjf "$SOURCE_FILE"
  fi

  cd "$SOURCE_DIR"

  echo "$UI_PREFIX Configuring MacPorts"
  ./configure \
  --prefix="$PREFIX" \
  --enable-readline \
  --with-applications-dir="$APPLICATIONS_DIR" \
  --with-frameworks-dir="$PREFIX"/Library/Frameworks \
  --with-install-group="$GROUP" \
  --with-install-user="$USER" \
  --with-macports-user=macports

  echo "$UI_PREFIX Building MacPorts"
  make -j"$JOBS"

  echo "$UI_PREFIX Installing MacPorts"
  make install

  #echo "$UI_PREFIX Testing MacPorts"
  #make test

  echo "$UI_PREFIX Cleaning MacPorts"
  make distclean
fi

echo "$UI_PREFIX Updating MacPorts"
"$PREFIX"/bin/port -N selfupdate

if [ "$PREFIX" != "/opt/local" ]; then
  if [ ! -L "$PREFIX"/var/macports/distfiles ]; then
    echo "$UI_PREFIX Linking distfiles to main distfiles"
    mkdir -p "$PREFIX"/var/macports
    test -d "$PREFIX"/var/macports
    mkdir -p /opt/local/var/macports/distfiles
    test -d /opt/local/var/macports/distfiles
    if [ -d "$PREFIX"/var/macports/distfiles ]; then
      tar -C "$PREFIX"/var/macports -cf - distfiles | tar -C /opt/local/var/macports -xkf - || true
      rm -rf "$PREFIX"/var/macports/distfiles
    fi
    ln -s /opt/local/var/macports/distfiles "$PREFIX"/var/macports/distfiles
  fi
fi

sed -i '' -E 's/^#?(startupitem_install[[:space:]]+).*$/\1no/' "$PREFIX"/etc/macports/macports.conf

if [ ! -x "$PREFIX"/bin/git ]; then
  echo "$UI_PREFIX Installing git"
  "$PREFIX"/bin/port -N install git
fi

if [ ! -d "$EXTRA_PORTS_WC" ]; then
  echo "$UI_PREFIX Cloning $EXTRA_PORTS_URL to $EXTRA_PORTS_WC"
  "$PREFIX"/bin/git clone "$EXTRA_PORTS_URL" "$EXTRA_PORTS_WC"
else
  echo "$UI_PREFIX Updating $EXTRA_PORTS_WC"
  "$PREFIX"/bin/git -C "$EXTRA_PORTS_WC" pull
fi

if ! grep -q "file://$EXTRA_PORTS_DIR" "$PREFIX"/etc/macports/sources.conf; then
  echo "$UI_PREFIX Adding $EXTRA_PORTS_DIR to sources.conf"
  echo "file://$EXTRA_PORTS_DIR" >> "$PREFIX"/etc/macports/sources.conf
  "$PREFIX"/bin/port -N sync
fi

case "$(basename "$SHELL")" in
  bash)
    PROFILE=.profile
    ;;
  zsh)
    PROFILE=.zprofile
    ;;
  *)
    echo "Don't know how to set up profile for shell $SHELL" 1>&2
    exit
esac
PROFILE="$HOME"/"$PROFILE"

if [ ! -f "$PROFILE" ]; then
  touch "$PROFILE"
  chown "$ORIG_USER":"$ORIG_GROUP" "$PROFILE"
fi
if ! grep -q "$PREFIX/bin:$PREFIX/sbin" "$PROFILE"; then
  echo "$UI_PREFIX Setting up profile"
  echo "export PATH=$PREFIX/bin:$PREFIX/sbin:\$PATH" >> "$PROFILE"
fi
