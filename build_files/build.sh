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

#### Example for enabling a System Unit File

systemctl enable podman.socket
