#!/bin/bash
# Executado DENTRO do container ubuntu:22.04 (glibc 2.35)
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive
VER=1.8.1
FSPKGS="e2fsprogs dosfstools mtools ntfs-3g exfatprogs btrfs-progs xfsprogs f2fs-tools jfsutils reiserfsprogs udftools nilfs-tools hfsprogs lvm2 cryptsetup-bin"
apt-get update
apt-get install -y --no-install-recommends build-essential pkg-config gettext itstool \
  libgtkmm-3.0-dev libparted-dev uuid-dev libpolkit-gobject-1-dev libglib2.0-dev \
  file wget ca-certificates librsvg2-common gnome-themes-extra adwaita-icon-theme-full \
  libgdk-pixbuf2.0-bin libgtk-3-bin desktop-file-utils squashfs-tools $FSPKGS

W=/work; B=/tmp/build; A=/tmp/AppDir; rm -rf $B $A; mkdir -p $B $A
tar xzf $W/gparted-$VER.tar.gz -C $B
cd $B/gparted-$VER
# Localização de traduções relocável (dentro do AppImage)
sed -i 's|bindtextdomain( GETTEXT_PACKAGE, GNOMELOCALEDIR ) ;|bindtextdomain( GETTEXT_PACKAGE, getenv("GPARTED_LOCALEDIR") ? getenv("GPARTED_LOCALEDIR") : GNOMELOCALEDIR ) ;|' src/main.cc
grep -q '<cstdlib>' src/main.cc || sed -i '0,/#include/s//#include <cstdlib>\n#include/' src/main.cc
./configure --prefix=/usr --libexecdir=/usr/libexec --disable-doc
make -j"$(nproc)"
make install DESTDIR=$A
# Wrapper oficial: aponta gpartedbin para dentro do AppDir
sed -i 's|/usr/libexec/gpartedbin|"$APPDIR"/usr/bin/gpartedbin|' $A/usr/bin/gparted
grep -n 'BASE_CMD=' $A/usr/bin/gparted

# Binários ELF ficam FORA do AppDir; o linuxdeploy os copia para usr/bin com RUNPATH=$ORIGIN/../lib
STG=/tmp/stage; rm -rf $STG; mkdir -p $STG
mv $A/usr/libexec/gpartedbin $STG/gpartedbin; rmdir $A/usr/libexec || true
EXES=(--executable $STG/gpartedbin)
SCRIPTS=(); LINKS=()
for p in $FSPKGS; do
  for f in $(dpkg -L $p | grep -E '^/(usr/)?s?bin/[^/]+$'); do
    [ -e "$f" ] || continue
    n=$(basename "$f")
    [ "$n" = gparted ] && continue
    if [ -L "$f" ] && [ "$(basename "$(readlink -f "$f")")" != "$n" ] && file -L "$f" | grep -q ELF; then
      LINKS+=("$n:$(basename "$(readlink -f "$f")")"); continue
    fi
    if file -L "$f" | grep -q ELF; then
      [ -e "$STG/$n" ] || { cp -L "$f" "$STG/$n"; EXES+=(--executable "$STG/$n"); }
    else
      cp -L "$f" "$A/usr/bin/$n"
    fi
  done
done
mkdir -p $A/usr/share/doc/gparted-appimage && dpkg -l $FSPKGS > $A/usr/share/doc/gparted-appimage/bundled-packages.txt

# Ferramentas de empacotamento
T=/tmp/tools; mkdir -p $T; cd $T
wget -q https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage
wget -q https://raw.githubusercontent.com/linuxdeploy/linuxdeploy-plugin-gtk/master/linuxdeploy-plugin-gtk.sh
wget -q https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage
chmod +x *.AppImage *.sh
export APPIMAGE_EXTRACT_AND_RUN=1 DEPLOY_GTK_VERSION=3 PATH=$T:$PATH

cp $W/AppRun $A/AppRun; chmod +x $A/AppRun
ICON=$(ls $A/usr/share/icons/hicolor/256x256/apps/gparted.png 2>/dev/null || ls $A/usr/share/icons/hicolor/*/apps/gparted.png | tail -1)
./linuxdeploy-x86_64.AppImage --appdir $A \
  "${EXES[@]}" \
  --desktop-file $A/usr/share/applications/gparted.desktop \
  --icon-file "$ICON" --custom-apprun $W/AppRun \
  --library /usr/lib/x86_64-linux-gnu/libgpg-error.so.0 \
  --library /usr/lib/x86_64-linux-gnu/libharfbuzz.so.0 \
  --library /usr/lib/x86_64-linux-gnu/libfribidi.so.0 \
  --plugin gtk
# Tema/ícones Adwaita para não depender do host
mkdir -p $A/usr/share/icons $A/usr/share/themes
cp -a /usr/share/icons/Adwaita /usr/share/icons/hicolor $A/usr/share/icons/ 2>/dev/null || true
cp -a /usr/share/themes/Adwaita* $A/usr/share/themes/ 2>/dev/null || true
cp $W/AppRun $A/AppRun; chmod +x $A/AppRun
# symlinks (lvcreate -> lvm, fsck.ext4 -> e2fsck, ...)
for l in "${LINKS[@]}"; do n=${l%%:*}; t=${l#*:}; [ -e "$A/usr/bin/$t" ] && ln -sf "$t" "$A/usr/bin/$n"; done
sed -i 's|^Exec=.*|Exec=gparted %f|' $A/*.desktop

mkdir -p $W/out
cd $W/out
ARCH=x86_64 VERSION=$VER $T/appimagetool-x86_64.AppImage --comp zstd $A $W/out/GParted-$VER-x86_64.AppImage
chown -R ${HOST_UID}:${HOST_GID} $W/out
ls -lh $W/out
