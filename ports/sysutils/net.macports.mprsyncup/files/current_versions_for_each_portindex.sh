#!/bin/bash

set -euo pipefail

: "${TMPDIR=/tmp}"

conf=$(mktemp "$TMPDIR/conf_XXXXXXXX")
sources=$(mktemp "$TMPDIR/sources_XXXXXXXX")

trap 'rm -f -- "$conf" "$sources"' EXIT INT TERM

printf "sources_conf %s\n" "$sources" > "$conf"

ports_dir=/Volumes/RAID@PREFIX@/var/rsync/macports/release/ports

for portindex in "$ports_dir"/PortIndex_*/PortIndex; do
    portindex_dir="${portindex%/*}"
    portindex_dirname="${portindex_dir##*/}"
    portindex_suffix="${portindex_dirname#PortIndex_}"
    printf "%s\n" "file://$portindex_dir [default]" > "$sources"
    PORTSRC="$conf" "@PREFIX@/bin/current_versions.tcl" | sed "s/^/$portindex_suffix /"
done
