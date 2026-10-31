# Universal Blue doesn't publish an XFCE image, so use Fedora's own XFCE Atomic bootc image
ARG BASE_IMAGE=quay.io/fedora-ostree-desktops/xfce-atomic:45

# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx
COPY build_files /
COPY system_files /system_files

### BLUECURVE BUILD
## Built on the same base image so the GTK 2 engine links against the image's own libraries.
FROM ${BASE_IMAGE} AS bluecurve

# Upstream commit to build. Bump this to pull in new upstream changes.
ARG BLUECURVE_REF=013ba225e78d9767b274ac6f16a67cb19f0673c6

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build-bluecurve.sh

# Base Image
FROM ${BASE_IMAGE}
## Other possible base images include:
# FROM ghcr.io/ublue-os/bazzite:stable
# FROM ghcr.io/ublue-os/aurora:stable
#
# ... and so on, here are more base images
# Universal Blue Images: https://github.com/orgs/ublue-os/packages
# Fedora base image: quay.io/fedora/fedora-bootc:45
# CentOS base images: quay.io/centos-bootc/centos-bootc:stream10

### [IM]MUTABLE /opt
## Some bootable images, like Fedora, have /opt symlinked to /var/opt, in order to
## make it mutable/writable for users. However, some packages write files to this directory,
## thus its contents might be wiped out when bootc deploys an image, making it troublesome for
## some packages. Eg, google-chrome, docker-desktop.
##
## Uncomment the following line if one desires to make /opt immutable and be able to be used
## by the package manager.

# RUN rm /opt && mkdir /opt

# Bluecurve GTK/xfwm4 themes, icons, cursors, fonts, wallpapers
COPY --from=bluecurve /out/ /

### MODIFICATIONS
## make modifications desired in your image and install packages by modifying the build.sh script
## the following RUN directive does all the things required to run "build.sh" as recommended.

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build.sh

### LINTING
## Verify final image and contents are correct.
RUN bootc container lint
