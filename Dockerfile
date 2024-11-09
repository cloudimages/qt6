ARG DISTRO=ubuntu-24.04
ARG USER=aosp
ARG UID=1001
ARG GID=1001
ARG CLANG_MAJOR=18
# clang source options:
# apt - directly use apt version
# llvm - add llvm distro repo
ARG CLANG_SOURCE=apt
ARG GCC_MAJOR=14
# gcc source options:
# apt - directly use apt version
# ppa - add toolchain ppa
ARG GCC_SOURCE=apt
ARG QTCREATOR_VERSION="13.0.2-patched"
ARG QTCREATOR_URL="https://github.com/hicknhack-software/Qt-Creator/releases/download/v13.0.2-patched/qtcreator-linux-x64-9428386763.7z"
ARG QT_ARCH=linux_gcc_64
ARG QT_VERSION=6.8.0
ARG QT_MODULES=qtshadertools
ARG RUNTIME_APT="libicu74 libglib2.0-0 libdbus-1-3 libpcre2-16-0"
# ARG RUNTIME_LUNAR="libicu72 libglib2.0-0 libdbus-1-3 libpcre2-16-0"
# ARG RUNTIME_XENIAL="libicu55 libglib2.0-0"

FROM python:3.10-slim AS qt_base
ARG QT_ARCH
ARG QT_VERSION
ARG QT_MODULES
ARG APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1
ARG DEBIAN_FRONTEND=noninteractive

RUN pip install aqtinstall

RUN \
  apt update --quiet \
  && apt-get install --yes --quiet --no-install-recommends \
    p7zip-full \
    libglib2.0-0 \
  && apt-get --yes autoremove \
  && apt-get clean autoclean \
  && rm -rf /var/lib/apt/lists/{apt,dpkg,cache,log} /tmp/* /var/tmp/*

RUN \
  mkdir /qt && cd /qt \
  && aqt install-qt linux desktop ${QT_VERSION} ${QT_ARCH} -m ${QT_MODULES} --external "7z"


FROM mcr.microsoft.com/devcontainers/cpp:${DISTRO} AS qtcreator_base
ARG DISTRO
ARG USER
ARG UID
ARG GID
ARG QTCREATOR_URL
ARG RUNTIME_APT
ARG APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1
ARG DEBIAN_FRONTEND=noninteractive

ENV \
  LANG=C.UTF-8 \
  LC_ALL=C.UTF-8 \
  DISPLAY=:0 \
  WAYLAND_DISPLAY=wayland-0

# install prerequisites to run qtcreator, tools and Qt
RUN \
  apt-get update --quiet \
  && apt-get upgrade --yes --quiet \
  && apt-get install --yes --quiet --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    gnupg \
    wget \
  && apt-get update --quiet \
  && apt-get install --yes --quiet --no-install-recommends \
    ${RUNTIME_APT} \
    sudo \
    git \
    vim \
    patch \
    ssh \
    make \
    p7zip-full \
    xterm \
    xdg-utils \
    libpulse0 \
    libdbus-1-3 \
    libgl1-mesa-dri \
    libglx-mesa0 \
    libxcb-keysyms1 \
    libxcb-render-util0 \
    libxcb-xfixes0 \
    libxcb-icccm4 \
    libxcb-image0 \
    libxcb-randr0 \
    libxcb-shape0 \
    libxcb-cursor0 \
    libgssapi-krb5-2 \
    libxcb-xinerama0 \
    libxcb-xkb1 \
    libxkbcommon-x11-0 \
    libxkbcommon-dev \
    libharfbuzz-icu0 \
    libegl1-mesa-dev \
    libglu1-mesa-dev \
    libwayland-egl1 \
    libwayland-cursor0 \
    build-essential \
  && apt-get --yes autoremove \
  && apt-get clean autoclean \
  && rm -rf /var/lib/apt/lists/{apt,dpkg,cache,log} /tmp/* /var/tmp/*

# preconfigure qtcreator
COPY config/qtversion.xml /home/${USER}/.config/QtProject/qtcreator/qtversion.xml
COPY config/QtCreator.ini /home/${USER}/.config/QtProject/QtCreator.ini

# add user for development
RUN \
  if [ "${UID}" = "1000" ] ; then userdel --remove ubuntu ; fi \
  && groupadd --gid ${GID} ${USER} \
  && useradd --create-home --home-dir /home/${USER} --shell /bin/bash ${USER} --uid ${UID} --gid ${GID} \
  && echo "${USER} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/${USER} \
  && chmod 0440 /etc/sudoers.d/${USER} \
  && mkdir -p /build \
  && chown ${UID}:${GID} -R /home/${USER} /build

WORKDIR /build


# COPY Qt /opt/qt6

USER ${USER}
ENV \
  HOME=/home/${USER} \
  XDG_RUNTIME_DIR=/tmp/runtime-${USER}
