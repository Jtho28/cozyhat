#!/bin/bash

set -ouex pipefail

# Copy the contents of system_files/ of the git repo to /
cp -avf "/ctx/system_files"/. /

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/45/x86_64/repoview/index.html&protocol=https&redirect=1

# this installs a package from fedora repos
# dnf5 install -y tmux
dnf5 install -y falkon

# Use a COPR Example:
#
# dnf5 -y copr enable ublue-os/staging
# dnf5 -y install package
# Disable COPRs so they don't end up enabled on the final image:
# dnf5 -y copr disable ublue-os/staging

### Bluecurve system-wide defaults
# New users get these from xfconf's system defaults. Existing users are switched over on their
# next login by /usr/libexec/cozyhat-bluecurve-session (xfwm4.xml is shipped in system_files).

fc-cache -f /usr/share/fonts/luxi

xsettings=/etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml
sed -i \
    -e 's|\(name="ThemeName" type="string" value="\)[^"]*"|\1Bluecurve"|' \
    -e 's|\(name="IconThemeName" type="string" value="\)[^"]*"|\1Bluecurve"|' \
    -e 's|\(name="CursorThemeName" type="string" value="\)[^"]*"|\1Bluecurve"|' \
    "$xsettings"
[[ $(grep -c 'value="Bluecurve"' "$xsettings") -eq 3 ]]

### Hibernation (laptops)
# Disk swapfile sized to RAM, created at boot on laptops only (see cozyhat-setup-swapfile).
# Lid close on battery does suspend-then-hibernate (logind.conf.d + sleep.conf.d).
chmod 755 /usr/libexec/cozyhat-setup-swapfile
systemctl enable cozyhat-swapfile.service var-swap-swapfile.swap

# xfce4-power-manager grabs the lid switch itself and only knows plain suspend; hand the lid
# back to logind so the suspend-then-hibernate setting applies.
xfpm=/etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-power-manager.xml
sed -i 's|\(name="logind-handle-lid-switch" type="bool" value="\)false"|\1true"|' "$xfpm"
grep -q 'name="logind-handle-lid-switch" type="bool" value="true"' "$xfpm"

### SELinux off
# The real switch is the selinux=0 kernel argument (usr/lib/bootc/kargs.d); this keeps the
# config file consistent with it.
sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config

#### Example for enabling a System Unit File

systemctl enable podman.socket
