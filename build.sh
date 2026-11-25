#!/bin/bash
# Gera out/GParted-<ver>-x86_64.AppImage usando container Ubuntu 22.04 (glibc 2.35).
# Requer: Docker, acesso à internet.
set -euo pipefail
cd "$(dirname "$0")"
VER=1.8.1
SHA256=67388ac405f9fe92a40636cb03b0e1e0bb6403ad89ccc174b2ff190ef6f32349
TARBALL=gparted-$VER.tar.gz
if [ ! -f "$TARBALL" ]; then
  curl -fL -o "$TARBALL" "https://downloads.sourceforge.net/project/gparted/gparted/gparted-$VER/$TARBALL"
fi
echo "$SHA256  $TARBALL" | sha256sum -c -
docker run --rm -e HOST_UID="$(id -u)" -e HOST_GID="$(id -g)" \
  -v "$PWD":/work ubuntu:22.04 bash /work/build-inside.sh
