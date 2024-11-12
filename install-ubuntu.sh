#!/data/data/com.termux/files/usr/bin/env bash

################################################################################
#                                                                              #
#     Termux Ubuntu Installer.                                                 #
#                                                                              #
#     Installs Ubuntu in Termux.                                               #
#                                                                              #
#     Copyright (C) 2023  Jore <https://github.com/jorexdeveloper>             #
#                                                                              #
#     This program is free software: you can redistribute it and/or modify     #
#     it under the terms of the GNU General Public License as published by     #
#     the Free Software Foundation, either version 3 of the License, or        #
#     (at your option) any later version.                                      #
#                                                                              #
#     This program is distributed in the hope that it will be useful,          #
#     but WITHOUT ANY WARRANTY; without even the implied warranty of           #
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            #
#     GNU General Public License for more details.                             #
#                                                                              #
#     You should have received a copy of the GNU General Public License        #
#     along with this program.  If not, see <https://www.gnu.org/licenses/>.   #
#                                                                              #
################################################################################
# shellcheck disable=SC2034

# ATTENTION!!! CHANGE BELOW!!!

# Called before any safety checks
# New Variables: AUTHOR GITHUB LOG_FILE ACTION_INSTALL ACTION_CONFIGURE
#                ROOTFS_DIRECTORY COLOR_SUPPORT all_available_colors
pre_check_actions() {
	return
}

# Called when printing intro
# New Variables: none
distro_banner() {
	local spaces=''
	for ((i = $((($(stty size | cut -d ' ' -f2) - 31) / 2)); i > 0; i--)); do
		spaces+=' '
	done
	msg -a "${spaces}       __             __"
	msg -a "${spaces} __ __/ /  __ _____  / /___ __"
	msg -a "${spaces}/ // / _ \/ // / _ \/ __/ // /"
	msg -a "${spaces}\_,_/_.__/\_,_/_//_/\__/\_,_/"
	msg -a "${spaces}     ${Y}${VERSION_NAME}${C}"
}

# Called after checking architecture and required pkgs
# New Variables: SYS_ARCH LIB_GCC_PATH
post_check_actions() {
	return
}

# Called after checking for rootfs directory
# New Variables: KEEP_ROOTFS_DIRECTORY
pre_install_actions() {
	ARCHIVE_NAME="${code_name}-server-cloudimg-${SYS_ARCH}-root.tar.xz"
}

# Called after extracting rootfs
# New Variables: KEEP_ROOTFS_ARCHIVE
post_install_actions() {
	return
}

# Called before making configurations
# New Variables: none
pre_config_actions() {
	return
}

# Called after configurations
# New Variables: none
post_config_actions() {
	local xstartup="$(
		cat 2>>"${LOG_FILE}" <<-EOF
			#!/bin/bash
			#############################
			##          All            ##
			export XDG_RUNTIME_DIR=/tmp/runtime-"\${USER-root}"
			export SHELL="\${SHELL-/usr/bin/sh}"

			unset SESSION_MANAGER
			unset DBUS_SESSION_BUS_ADDRESS

			xrdb "\${HOME-/tmp}"/.Xresources

			#############################
			##          Gnome          ##
			export XKL_XMODMAP_DISABLE=1
			exec gnome-session

			############################
			##           LXQT         ##
			# exec startlxqt

			############################
			##          KDE           ##
			# exec startplasma-x11

			############################
			##          XFCE          ##
			# export QT_QPA_PLATFORMTHEME=qt5ct
			# exec startxfce4

			############################
			##           i3           ##
			# exec i3
		EOF
	)"
	{
		mkdir -p "${ROOTFS_DIRECTORY}/root/.vnc"
		echo "${xstartup}" >"${ROOTFS_DIRECTORY}/root/.vnc/xstartup"
		chmod 744 "${ROOTFS_DIRECTORY}/root/.vnc/xstartup"
		if [ "${DEFAULT_LOGIN}" != "root" ]; then
			mkdir -p "${ROOTFS_DIRECTORY}/${DEFAULT_LOGIN}/.vnc"
			echo "${xstartup}" >"${ROOTFS_DIRECTORY}/home/${DEFAULT_LOGIN}/.vnc/xstartup"
			chmod 744 "${ROOTFS_DIRECTORY}/home/${DEFAULT_LOGIN}/.vnc/xstartup"
		fi
	} 2>>"${LOG_FILE}"
}

# Called before complete message
# New Variables: none
pre_complete_actions() {
	return
}

# Called after clean up and complete message
# Print any extra messages here
post_complete_actions() {
	if ${ACTION_INSTALL}; then
		msg -te "Remember, this is a minimal installation of ${DISTRO_NAME}."
		msg "If you need to install additional packages, check out the documentation for a guide."
	fi
}

version="22.04"
code_name="noble"
release="20241004"

DISTRO_NAME="Ubuntu"
PROGRAM_NAME="$(basename "${0}")"
DISTRO_REPOSITORY="termux-ubuntu"
VERSION_NAME="${version} ${code_name}-${release}"

SHASUM_TYPE=256
TRUSTED_SHASUMS="$(
	cat <<-EOF
		72beaa1e14a7966956169ebf7d9c744701cb0ba8a52595f324e8a99ae9fee144 *noble-server-cloudimg-arm64-root.tar.xz
		b50cb095fe8827fca4e8fb98d46e310d92148af547b709fbabb29fea50fcbe8a *noble-server-cloudimg-armhf-root.tar.xz
	EOF
)"

ARCHIVE_STRIP_DIRS=0
KERNEL_RELEASE="6.2.1-ubuntu-proot"
BASE_URL="https://cloud-images.ubuntu.com/${code_name}/${release}"

TERMUX_FILES_DIR="/data/data/com.termux/files"

DISTRO_SHORTCUT="${TERMUX_FILES_DIR}/usr/bin/ub"
DISTRO_LAUNCHER="${TERMUX_FILES_DIR}/usr/bin/ubuntu"

DEFAULT_ROOTFS_DIR="${TERMUX_FILES_DIR}/ubuntu"
DEFAULT_LOGIN="root"

# WARNING!!! DO NOT CHANGE BELOW!!!

# Check in script's directory for template
distro_template="$(realpath "$(dirname "${0}")")/termux-distro.sh"
# shellcheck disable=SC1090
if [ -f "${distro_template}" ] && [ -r "${distro_template}" ]; then
	source "${distro_template}" "${@}"
elif curl -fsSLO "https://raw.githubusercontent.com/jorexdeveloper/termux-distro/main/termux-distro.sh" 2>"/dev/null" && [ -f "${distro_template}" ]; then
	source "${distro_template}"
else
	echo "You need an active internet connection to run this script."
fi
