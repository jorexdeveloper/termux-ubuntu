#!/data/data/com.termux/files/usr/bin/bash

################################################################################
#                                                                              #
#     Termux Ubuntu Installer.                                                 #
#                                                                              #
#     Installs Ubuntu in Termux.                                               #
#                                                                              #
#     Copyright (C) 2023-2025  Jore <https://github.com/jorexdeveloper>        #
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

# ATTENTION!!! CHANGE BELOW FUNTIONS FOR DISTRO DEPENDENT ACTIONS!!!

# Called before any safety checks
# New Variables: AUTHOR GITHUB LOG_FILE ACTION_INSTALL ACTION_CONFIGURE
#                ROOTFS_DIRECTORY COLOR_SUPPORT all_available_colors
pre_check_actions() {
	return
}

# Called before printing intro
# New Variables: none
distro_banner() {
	local spaces=''
	for ((i = $((($(stty size | cut -d ' ' -f2) - 40) / 2)); i > 0; i--)); do
		spaces+=' '
	done
	msg -a "${spaces}${R}            .-/+oossssoo+/-."
	msg -a "${spaces}${R}        ':+ssssssssssssssssss+:'"
	msg -a "${spaces}${R}      -+ssssssssssssssssssyyssss+-"
	msg -a "${spaces}${R}    .osssssssssssssssss ${N}dMMMN ${R}sssso."
	msg -a "${spaces}${R}   /ssssssssss ${N}hdmmNNmmyNMMMM ${R}ssssss/"
	msg -a "${spaces}${R}  +ssssssss h y ${N}MMMMMMMNdddd ${R}ssssssss+"
	msg -a "${spaces}${R} /sssssss ${N}hNMM ${R}y ${N}hyyyyhmNMMMN ${R}ssssssss/"
	msg -a "${spaces}${R}.sssssss ${N}dMMMN ${R}sssssssss ${N}hNMMM ${R}ssssssss."
	msg -a "${spaces}${R}+sss ${N}hhhyNMMN ${R}sssssssssss ${N}yNMMM ${R}sssssss+"
	msg -a "${spaces}${R}os ${N}yNMMMNyMM ${R}sssssssssssss ${N}hmmm ${R}ssssssso"
	msg -a "${spaces}${R}os ${N}yNMMMNyMM ${R}sssssssssssssshmmmh${R}ssssssso"
	msg -a "${spaces}${R}+sss ${N}hhhyNMMN ${R}sssssssssss ${N}yNMMM ${R}sssssss+"
	msg -a "${spaces}${R}.sssssss ${N}dMMMN ${R}sssssssss ${N}hNMMM ${R}ssssssss."
	msg -a "${spaces}${R} /sssssss ${N}hNMM ${R}y ${N}hyyyyhdNMMMN ${R}ssssssss/"
	msg -a "${spaces}${R}  +ssssssss d y ${N}MMMMMMMMdddd ${R}ssssssss+"
	msg -a "${spaces}${R}   /ssssssssss ${N}hdmNNNNmyNMMMM ${R}ssssss/"
	msg -a "${spaces}${R}    .osssssssssssssssss ${N}dMMMN ${R}sssso."
	msg -a "${spaces}${R}      -+ssssssssssssssss ${N}yy ${R}ssss+-"
	msg -a "${spaces}${R}        ':+ssssssssssssssssss+:'"
	msg -a "${spaces}${R}            .-/+oossssoo+/-."
	msg -a "${spaces}       ${DISTRO_NAME} ${Y}${VERSION_NAME}"
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
	msg -t "Lemme create an xstartup script for vnc."
	local xstartup="$(
		# Customize depending on distribution defaults
		cat 2>>"${LOG_FILE}" <<-EOF
			#!/bin/bash
			#############################
			##          All            ##
			unset SESSION_MANAGER
			unset DBUS_SESSION_BUS_ADDRESS

			export XDG_RUNTIME_DIR=/tmp/runtime-"\${USER:-root}"
			export SHELL="\${SHELL:-/bin/sh}"

			if [ -r ~/.Xresources ]; then
			    xrdb ~/.Xresources
			fi

			#############################
			##          Gnome          ##
			# exec gnome-session

			############################
			##           LXQT         ##
			# exec startlxqt

			############################
			##          KDE           ##
			# exec startplasma-x11

			############################
			##          XFCE          ##
			export QT_QPA_PLATFORMTHEME=qt5ct
			exec startxfce4

			############################
			##           i3           ##
			# exec i3

			############################
			##        BLACKBOX        ##
			# exec blackbox
		EOF
	)"
	if {
		mkdir -p "${ROOTFS_DIRECTORY}/root/.vnc"
		echo "${xstartup}" >"${ROOTFS_DIRECTORY}/root/.vnc/xstartup"
		chmod 744 "${ROOTFS_DIRECTORY}/root/.vnc/xstartup"
		if [ "${DEFAULT_LOGIN}" != "root" ]; then
			mkdir -p "${ROOTFS_DIRECTORY}/home/${DEFAULT_LOGIN}/.vnc"
			echo "${xstartup}" >"${ROOTFS_DIRECTORY}/home/${DEFAULT_LOGIN}/.vnc/xstartup"
			chmod 744 "${ROOTFS_DIRECTORY}/home/${DEFAULT_LOGIN}/.vnc/xstartup"
		fi
	} 2>>"${LOG_FILE}"; then
		msg -s "Done, xstartup script created successfully!"
	else
		msg -e "Sorry, I failed to create the xstartup script for vnc."
	fi
}

# Called before making configurations
# New Variables: none
pre_config_actions() {
	return
}

# Called after configurations
# New Variables: none
post_config_actions() {
	# execute distro specific command for locale generation
	if [ -f "${ROOTFS_DIRECTORY}/etc/locale.gen" ] && [ -x "${ROOTFS_DIRECTORY}/sbin/dpkg-reconfigure" ]; then
		msg -t "Hold on while I generate the locales for you."
		sed -i -E 's/#[[:space:]]?(en_US.UTF-8[[:space:]]+UTF-8)/\1/g' "${ROOTFS_DIRECTORY}/etc/locale.gen"
		if distro_exec DEBIAN_FRONTEND=noninteractive /sbin/dpkg-reconfigure locales &>>"${LOG_FILE}"; then
			msg -s "Done, the locales are ready!"
		else
			msg -e "Sorry, I failed to generate the locales."
		fi
	fi
}

# Called before complete message
# New Variables: none
pre_complete_actions() {
	return
}

# Called after complete message
# New Variables: none
post_complete_actions() {
	if ${ACTION_INSTALL}; then
		msg -te "Remember, this is a minimal installation of ${DISTRO_NAME}."
		msg "If you need to install additional packages, check out the documentation for a guide."
	fi
}

# These variables are
# only used in this script:
# 		name, code_name, release

name="22.04 LTS"
code_name="noble"
release="20250430"

DISTRO_NAME="Ubuntu"
PROGRAM_NAME="$(basename "${0}")"
DISTRO_REPOSITORY="termux-ubuntu"
VERSION_NAME="${name} ${code_name}-${release}"

SHASUM_CMD=sha256sum
TRUSTED_SHASUMS="$(
	cat <<-EOF
		627ad88c92c0309a6addf1b860eec798874e92ad9c0d2bd4712a54a0c9a59738 *noble-server-cloudimg-arm64-root.tar.xz
		d18540347689dc26390df2a9c0b8d59117eeb4e35b873966ab09b27dcba58683 *noble-server-cloudimg-armhf-root.tar.xz
	EOF
)"

ARCHIVE_STRIP_DIRS=0 # directories stripped by tar when extracting rootfs archive
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
