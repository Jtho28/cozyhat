#!/bin/bash
# Builds neeeeow/Bluecurve and stages the result in /out, which the final image stage copies over /.

set -ouex pipefail

dnf5 install -y --setopt=install_weak_deps=False \
    cmake gcc gcc-c++ make pkgconf-pkg-config python3 python3-lxml \
    gtk-update-icon-cache gtk2-devel gtk3-devel

mkdir -p /tmp/src
curl -fsSL "https://github.com/neeeeow/Bluecurve/archive/${BLUECURVE_REF}.tar.gz" |
    tar -xz --strip-components=1 -C /tmp/src

cmake -S /tmp/src -B /tmp/build -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release
cmake --build /tmp/build -j"$(nproc)"
DESTDIR=/out cmake --install /tmp/build

# Not installed by upstream's CMake
install -Dm644 -t /out/usr/share/fonts/luxi /tmp/src/fonts/*.ttf
install -Dm644 -t /out/usr/share/licenses/luxi-fonts /tmp/src/fonts/COPYING /tmp/src/fonts/COPYRIGHT.BH
install -Dm644 -t /out/usr/share/backgrounds/bluecurve /tmp/src/wallpapers/*.png
