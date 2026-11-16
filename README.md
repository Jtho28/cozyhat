# cozyhat

[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/cozyhat)](https://artifacthub.io/packages/search?repo=cozyhat)

A [bootc](https://github.com/bootc-dev/bootc) image based on Fedora's
[XFCE Atomic](https://quay.io/repository/fedora-ostree-desktops/xfce-atomic) with the
[Bluecurve](https://github.com/neeeeow/Bluecurve) theme built in: GTK 2/3/4 and xfwm4 themes,
icons, cursors, Luxi fonts and wallpapers (in `/usr/share/backgrounds/bluecurve`). The upstream
commit is pinned with the `BLUECURVE_REF` build arg in the `Containerfile`.

Bluecurve, its icons and cursors, and the Bluecurve xfwm4 theme are the system-wide xfconf defaults.
On first login, `/usr/libexec/cozyhat-bluecurve-session` applies them to existing users too. On every
login it syncs the Bluecurve GTK themes into `~/.local/share/themes` so that Flatpak apps can use them
(a system-wide Flatpak override grants read-only access to that folder and `~/.config/gtk-{3,4}.0`).

Rebase onto it with `rpm-ostree` (unlike `bootc switch`, this keeps any locally layered packages):

```bash
rpm-ostree rebase ostree-unverified-registry:ghcr.io/jtho28/cozyhat:latest
```

---
