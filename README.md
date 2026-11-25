# GParted 1.8.1 – AppImage autocontido

AppImage não-oficial do [GParted](https://gparted.org) 1.8.1, compilado a partir do
código-fonte oficial (SHA-256 verificado no build), com as ferramentas de sistemas de
arquivos embutidas. Não requer instalação de nenhum pacote.

> ⚠️ O GParted altera discos diretamente. Faça backup antes de qualquer operação.

## Download
Baixe `GParted-1.8.1-x86_64.AppImage` na página de
[Releases](../../releases). O código-fonte correspondente do GParted (GPL-2.0)
está anexado na mesma release.

## Uso
    chmod +x GParted-1.8.1-x86_64.AppImage
    ./GParted-1.8.1-x86_64.AppImage        # pede senha de admin (pkexec ou sudo)

Variáveis opcionais:
- `GPARTED_PREFER_HOST_TOOLS=1` – usa mkfs/fsck/resize do sistema quando existirem
  (ferramentas embutidas viram só fallback). Útil para FS criados com features
  mais novas que as versões embutidas (ex.: ext4 `orphan_file`, e2fsprogs >= 1.47).
- `GPARTED_COLOR_SCHEME=dark|light` – força o modo de cor (padrão: detecta via
  portal XDG, gsettings, settings.ini do GTK ou kdeglobals, como usuário, antes do pkexec).
- `GPARTED_THEME=adwaita` – ignora o tema do usuário e usa o Adwaita embutido
  (ou `GPARTED_THEME=<nome>` para um tema GTK3 específico).
- `APPIMAGE_EXTRACT_AND_RUN=1` – roda sem FUSE (extrai em /tmp).

## Rebuild
    ./build.sh      # requer Docker + internet; gera out/GParted-1.8.1-x86_64.AppImage

Build em container Ubuntu 22.04 (glibc 2.35) → roda em distros com glibc >= 2.35
(Ubuntu 22.04+, Debian 12+, Fedora 36+, RHEL/Alma/Rocky 10, openSUSE Tumbleweed,
Arch, Mint 21+, Pop!_OS 22.04+…).

## O que vai dentro
- gpartedbin + gtkmm3/GTK3/libparted/glib + tema/ícones Adwaita + traduções
- Ferramentas: e2fsprogs, dosfstools, mtools, ntfs-3g, exfatprogs, btrfs-progs,
  xfsprogs, f2fs-tools, jfsutils, reiserfsprogs, udftools, nilfs-tools, hfsprogs,
  lvm2, cryptsetup (lista exata: usr/share/doc/gparted-appimage/bundled-packages.txt)
- Wrapper oficial `gparted` (mascara automount do systemd e regras udev de
  RAID/LVM durante a execução)

## Comportamentos adicionados no AppRun
- Tema e ícones do usuário (ex.: adw-gtk3-dark + um tema de ícones escuro) são repassados ao
  processo root; se não forem encontrados, usa Adwaita claro/escuro conforme o sistema.
- Inibe a montagem automática do udisks2 durante a sessão (regra temporária
  `/run/udev/rules.d/90-gparted-appimage-udisks-inhibit.rules`, removida ao sair)
  quando a distro não tem `udisks2-inhibit` (ex.: Arch). Evita "Device or resource busy".

## Vem do sistema (intencional)
glibc, libX11/libxcb, libwayland-client, fontconfig/freetype (presentes em qualquer
desktop gráfico; embuti-los causa conflito com o servidor gráfico), util-linux
(mount/umount/blkid), pkexec/sudo, systemctl/udev.

## Modificações no fonte (aplicadas no build, tarball original intacto)
- `src/main.cc`: `bindtextdomain` lê `GPARTED_LOCALEDIR` (traduções relocáveis).
- wrapper `gparted`: caminho de `gpartedbin` relativo a `$APPDIR`.

## Dicas
- **Pendrive com ISO gravada** (ex.: ISO de instalação de Linux): ejete o pendrive no
  gerenciador de arquivos antes de abrir o GParted. Imagens ISO "híbridas" fazem o
  GParted ver o disco inteiro como iso9660 e ele não detecta a partição montada,
  resultando em "Device or resource busy" (comportamento do GParted upstream).
  Prefira criar uma tabela de partição (msdos/gpt) e depois a partição.

## Licença
GParted e as ferramentas embutidas são distribuídos sob suas respectivas licenças
(GParted: GPL-2.0-or-later). Os scripts deste repositório: GPL-2.0-or-later (ver `LICENSE`).
