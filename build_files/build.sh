#!/bin/bash

set -ouex pipefail

### XFCE desktop
# The base (ublue-os/base-main) has no desktop. This list mirrors what Fedora's XFCE Atomic
# image ships, minus its live-installer bits (anaconda, initial-setup) and ffmpeg-free, since
# the ublue base already carries the full RPM Fusion ffmpeg.
xfce_packages=(
    # Core session
    xfce4-session xfce4-panel xfce4-settings xfdesktop xfwm4 xfwm4-themes xfconf
    xfce4-appfinder xfce4-about xfce4-notifyd xfce4-power-manager xfce4-screensaver
    xfce4-terminal xfce4-taskmanager xfce4-panel-profiles xfce-polkit
    xfdashboard xfdashboard-themes
    # Panel plugins
    xfce4-battery-plugin xfce4-clipman-plugin xfce4-cpugraph-plugin xfce4-datetime-plugin
    xfce4-dict xfce4-dict-plugin xfce4-diskperf-plugin xfce4-eyes-plugin xfce4-fsguard-plugin
    xfce4-mailwatch-plugin xfce4-mount-plugin xfce4-netload-plugin xfce4-places-plugin
    xfce4-pulseaudio-plugin xfce4-screenshooter xfce4-screenshooter-plugin
    xfce4-systemload-plugin xfce4-time-out-plugin xfce4-verve-plugin xfce4-weather-plugin
    xfce4-whiskermenu-plugin xfce4-xkb-plugin
    # Apps
    Thunar thunar-archive-plugin thunar-media-tags-plugin thunar-volman tumbler
    mousepad ristretto atril galculator xarchiver gparted pavucontrol blueman
    falkon
    # Login screen
    lightdm lightdm-gtk
    # Themes, icons, fonts, backgrounds (gtk2 is needed by the Bluecurve GTK 2 engine)
    gtk2 gtk-xfce-engine gtk-murrine-engine greybird-dark-theme greybird-light-theme
    greybird-xfce4-notifyd-theme greybird-xfwm4-theme mint-y-theme mint-y-icons
    gnome-icon-theme dejavu-sans-mono-fonts desktop-backgrounds-compat f45-backgrounds-base
    # Networking
    network-manager-applet nm-connection-editor nm-connection-editor-desktop
    NetworkManager-openconnect-gnome NetworkManager-openvpn-gnome NetworkManager-team
    # Desktop plumbing
    gvfs gvfs-mtp xdg-user-dirs xdg-user-dirs-gtk oo7-daemon oo7-portal pam_oo7 ibus-gtk2
    redhat-menus wsdd fedora-flathub-remote fedora-third-party
    # X11
    xorg-x11-server-Xorg xorg-x11-xinit xorg-x11-drv-libinput xorg-x11-drv-evdev
    xorg-x11-drv-amdgpu xorg-x11-drv-ati xorg-x11-drv-intel xorg-x11-drv-nouveau
    xorg-x11-drv-qxl xorg-x11-drv-vmware xorg-x11-drv-openchrome xorg-x11-drv-wacom
    xrdb xset xmodmap setxkbmap iceauth glx-utils xdriinfo
)
dnf5 install -y "${xfce_packages[@]}"

# Falkon is the browser; drop the base image's Firefox.
dnf5 remove -y firefox firefox-langpacks

systemctl enable lightdm.service
systemctl set-default graphical.target

# Shipped xfconf files REPLACE the packages' copies. A leaf property with type="empty" (what
# exporting from ~/.config/xfce4 produces for untouched settings) wipes that default; in
# xfce4-session.xml it breaks login entirely ("Unable to load a failsafe session").
if grep -l 'type="empty"/>' /ctx/system_files/etc/xdg/xfce4/xfconf/xfce-perchannel-xml/*.xml; then
    echo "ERROR: blank xfconf properties in the files above; give them real values or remove them" >&2
    exit 1
fi

# Copy the contents of system_files/ of the git repo to /
# (after installing packages, so RPM can't replace the shipped XFCE configs)
cp -avf "/ctx/system_files"/. /

# cp -a carries over the build checkout's permissions, and git doesn't track directory modes,
# so a 700 dir in a local checkout became root-only in the image (users couldn't read the
# xfconf defaults -> "Unable to load a failsafe session"). Normalize everything we shipped:
# dirs 755, files 644, keeping the executable bit where git has it.
(cd /ctx/system_files && find . -mindepth 1 -type d -print0) | (cd / && xargs -0 chmod 755)
(cd /ctx/system_files && find . -type f -print0) | (cd / && xargs -0 chmod u=rwX,go=rX)

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/45/x86_64/repoview/index.html&protocol=https&redirect=1

### Default browser: Falkon
# XFCE's "Preferred Applications" (exo) has no Falkon helper upstream; one is shipped in
# system_files/usr/share/xfce4/helpers/falkon.desktop. MIME defaults are in /etc/xdg/mimeapps.list.
sed -i 's|^WebBrowser=.*|WebBrowser=falkon|' /etc/xdg/xfce4/helpers.rc
grep -qx 'WebBrowser=falkon' /etc/xdg/xfce4/helpers.rc
[[ -f /usr/share/applications/org.kde.falkon.desktop ]]

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

#### Example for enabling a System Unit File

systemctl enable podman.socket

### Repo files for the ISO installer
# Fedora 45 moved its .repo files to /usr/share/dnf5/repos.d. dnf5 reads them there, but
# bootc-image-builder's anaconda-iso build only reads /etc/yum.repos.d and fails with
# "There are no enabled repositories". Link each one back; same-named files mean dnf5 still
# sees each repo once.
for repo in /usr/share/dnf5/repos.d/*.repo; do
    [[ -e /etc/yum.repos.d/${repo##*/} ]] || ln -s "../../usr/share/dnf5/repos.d/${repo##*/}" /etc/yum.repos.d/
done
[[ -e /etc/yum.repos.d/fedora.repo ]]
