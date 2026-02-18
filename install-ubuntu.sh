#!/data/data/com.termux/files/usr/bin/bash

################################################################################
#                                                                              #
# Termux Ubuntu Installer.                                                     #
#                                                                              #
# Installs Ubuntu in Termux.                                                   #
#                                                                              #
# Copyright (C) 2023-2025  Jore <https://github.com/jorexdeveloper>            #
#                                                                              #
# This program is free software: you can redistribute it and/or modify         #
# it under the terms of the GNU General Public License as published by         #
# the Free Software Foundation, either version 3 of the License, or            #
# (at your option) any later version.                                          #
#                                                                              #
# This program is distributed in the hope that it will be useful,              #
# but WITHOUT ANY WARRANTY; without even the implied warranty of               #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the                #
# GNU General Public License for more details.                                 #
#                                                                              #
# You should have received a copy of the GNU General Public License            #
# along with this program.  If not, see <https://www.gnu.org/licenses/>.       #
#                                                                              #
################################################################################
# shellcheck disable=SC2034,SC2155

# ATTENTION!!! CHANGE BELOW FUNTIONS FOR DISTRO DEPENDENT ACTIONS!!!

################################################################################
# Called before any safety checks                                              #
# New Variables: AUTHOR GITHUB LOG_FILE ACTION_INSTALL ACTION_CONFIGURE        #
#                ROOTFS_DIRECTORY COLOR_SUPPORT (all available colors)         #
################################################################################
pre_check_actions() {
	P=${W} # primary color
	S=${R} # secondary color
	T=${M} # tertiary color
}

################################################################################
# Called before printing intro                                                 #
# New Variables: none                                                          #
################################################################################
distro_banner() {
	local spaces=$(printf "%*s" $((($(stty size | awk '{print $2}') - 40) / 2)) "")
	msg -a "${spaces}${S}            .-/+oossssoo+/-."
	msg -a "${spaces}${S}        ':+ssssssssssssssssss+:'"
	msg -a "${spaces}${S}      -+ssssssssssssssssssyyssss+-"
	msg -a "${spaces}${S}    .osssssssssssssssss ${N}dMMMN ${S}sssso."
	msg -a "${spaces}${S}   /ssssssssss ${N}hdmmNNmmyNMMMM ${S}ssssss/"
	msg -a "${spaces}${S}  +ssssssss h y ${N}MMMMMMMNdddd ${S}ssssssss+"
	msg -a "${spaces}${S} /sssssss ${N}hNMM ${S}y ${N}hyyyyhmNMMMN ${S}ssssssss/"
	msg -a "${spaces}${S}.sssssss ${N}dMMMN ${S}sssssssss ${N}hNMMM ${S}ssssssss."
	msg -a "${spaces}${S}+sss ${N}hhhyNMMN ${S}sssssssssss ${N}yNMMM ${S}sssssss+"
	msg -a "${spaces}${S}os ${N}yNMMMNyMM ${S}sssssssssssss ${N}hmmm ${S}ssssssso"
	msg -a "${spaces}${S}os ${N}yNMMMNyMM ${S}sssssssssssssshmmmh${S}ssssssso"
	msg -a "${spaces}${S}+sss ${N}hhhyNMMN ${S}sssssssssss ${N}yNMMM ${S}sssssss+"
	msg -a "${spaces}${S}.sssssss ${N}dMMMN ${S}sssssssss ${N}hNMMM ${S}ssssssss."
	msg -a "${spaces}${S} /sssssss ${N}hNMM ${S}y ${N}hyyyyhdNMMMN ${S}ssssssss/"
	msg -a "${spaces}${S}  +ssssssss d y ${N}MMMMMMMMdddd ${S}ssssssss+"
	msg -a "${spaces}${S}   /ssssssssss ${N}hdmNNNNmyNMMMM ${S}ssssss/"
	msg -a "${spaces}${S}    .osssssssssssssssss ${N}dMMMN ${S}sssso."
	msg -a "${spaces}${S}      -+ssssssssssssssss ${N}yy ${S}ssss+-"
	msg -a "${spaces}${S}        ':+ssssssssssssssssss+:'"
	msg -a "${spaces}${S}            .-/+oossssoo+/-."
	msg -a "${spaces}    ${P}${DISTRO_NAME}${S} ${T}${VERSION_NAME}${S}"
}

################################################################################
# Called after checking architecture and required pkgs                         #
# New Variables: SYS_ARCH LIB_GCC_PATH                                         #
################################################################################
post_check_actions() {
	return
}

################################################################################
# Called after checking for rootfs directory                                   #
# New Variables: KEEP_ROOTFS_DIRECTORY                                         #
################################################################################
pre_install_actions() {
	ARCHIVE_NAME=${code_name}-server-cloudimg-${SYS_ARCH}-root.tar.xz
}

################################################################################
# Called after extracting rootfs                                               #
# New Variables: KEEP_ROOTFS_ARCHIVE                                           #
################################################################################
post_install_actions() {
	return
}

################################################################################
# Called before making configurations                                          #
# New Variables: none                                                          #
################################################################################
pre_config_actions() {
	mkdir -p "${ROOTFS_DIRECTORY}"/etc &>>"${LOG_FILE}" && echo "${ROOTFS_DIRECTORY}" >"${ROOTFS_DIRECTORY}"/etc/debian_chroot
}

################################################################################
# Called after configurations                                                  #
# New Variables: none                                                          #
################################################################################
post_config_actions() {
	if [[ -f ${ROOTFS_DIRECTORY}/etc/locale.gen && -x ${ROOTFS_DIRECTORY}/sbin/dpkg-reconfigure ]]; then
		msg -tn "Generating locales..."
		sed -i -E 's/#[[:space:]]?(en_US.UTF-8[[:space:]]+UTF-8)/\1/g' "${ROOTFS_DIRECTORY}"/etc/locale.gen

		if distro_exec DEBIAN_FRONTEND=noninteractive /sbin/dpkg-reconfigure locales &>>"${LOG_FILE}"; then
			cursor -u1
			msg -ts "Locales generated"
		else
			cursor -u1
			msg -te "Failed to generate locales."
		fi
	fi
}

################################################################################
# Called before complete message                                               #
# New Variables: none                                                          #
################################################################################
pre_complete_actions() {
	if [[ ! ${DE_INSTALLED} ]] && ask -y -- -t "Install Desktop Environment?"; then
		set_up_de && {
			DE_INSTALLED=1
			set_up_browser
		}
	fi
}

################################################################################
# Called after complete message                                                #
# New Variables: none                                                          #
################################################################################
post_complete_actions() {
	return
}

################################################################################
# Local Functions                                                              #
################################################################################

# Sets up the desktop environment
set_up_de() {
	if command -v termux-wake-lock &>>"${LOG_FILE}"; then
		msg -tn "Acquiring Termux wake lock..."

		if termux-wake-lock &>>"${LOG_FILE}"; then
			cursor -u1
			msg -ts "Termux wake lock held"
		else
			cursor -u1
			msg -te "Failed to acquire Termux wake lock"
		fi
	fi

	msg -tn "Installing desktop packages in ${DISTRO_NAME}..."
	trap 'buffer -h; echo; msg -fem2; exit 130' INT
	buffer -s

	local pkgs=(tigervnc-standalone-server dbus-x11 xubuntu-desktop-minimal)
	if buffer -i apt update && distro_exec apt update &&
		buffer -i apt full-upgrade && distro_exec apt full-upgrade &&
		buffer -i apt install -y "${pkgs[@]}" && distro_exec apt install -y "${pkgs[@]}"; then
		buffer -h3
		trap - INT
		cursor -u1
		msg -ts "Desktop packages installed in ${DISTRO_NAME}"

		msg -tn "Creating xstartup program..."

		local xstartup=$(
			cat 2>>"${LOG_FILE}" <<-EOF
				#!/bin/bash
				unset SESSION_MANAGER
				unset DBUS_SESSION_BUS_ADDRESS

				export XDG_RUNTIME_DIR=\${TMPDIR:-/tmp}/runtime-"\$(id -u)"
				export SHELL=\${SHELL:-/bin/sh}

				if [[ -r ~/.Xresources ]]; then
				    xrdb ~/.Xresources
				fi

				exec startxfce4
			EOF
		)

		if {
			mkdir -p "${ROOTFS_DIRECTORY}"/root/.vnc &&
				echo "${xstartup}" >"${ROOTFS_DIRECTORY}"/root/.vnc/xstartup &&
				chmod 744 "${ROOTFS_DIRECTORY}"/root/.vnc/xstartup &&
				if [[ ${DEFAULT_LOGIN} != root ]]; then
					mkdir -p "${ROOTFS_DIRECTORY}"/home/"${DEFAULT_LOGIN}"/.vnc &&
						echo "${xstartup}" >"${ROOTFS_DIRECTORY}"/home/"${DEFAULT_LOGIN}"/.vnc/xstartup &&
						chmod 744 "${ROOTFS_DIRECTORY}"/home/"${DEFAULT_LOGIN}"/.vnc/xstartup
				fi
		} 2>>"${LOG_FILE}"; then
			cursor -u1
			msg -ts "Xstartup program created"
		else
			cursor -u1
			msg -te "Failed create xstartup program"
		fi
	else
		buffer -h5
		trap - INT
		cursor -u1
		msg -te "Failed to install Desktop packages in ${DISTRO_NAME}"
		return 1
	fi
}

# Sets up the Browser
set_up_browser() {
	local available_browsers selected_browser selected_browsers suffix
	available_browsers=(
		"Chromium" "Firefox" "Chromium & Firefox"
	)

	choose -d2 -t "Select Browser" \
		"${available_browsers[@]}"
	selected_browser=${available_browsers[$((${?} - 1))]}

	if [[ ${selected_browser} == "${available_browsers[-1]}" ]]; then
		selected_browsers=("${available_browsers[@]:0:${#available_browsers[@]}-1}")
		selected_browsers=("${selected_browsers[@]// /-}")
		suffix=s
	else
		selected_browsers=("${selected_browser// /-}")
		suffix=
	fi

	msg -tn "Installing ${selected_browser} Browser${suffix}..."
	trap 'buffer -h; echo; msg -fem2; exit 130' INT
	buffer -s

	if buffer -i apt install -y "${selected_browsers[@],,}" && distro_exec apt install -y "${selected_browsers[@],,}"; then
		if [[ ${selected_browsers[0]} == "${available_browsers[0]}" && -f "${ROOTFS_DIRECTORY}"/usr/share/applications/chromium.desktop ]]; then
			sed -Ei 's/^(Exec=.*chromium).*(%U)$/\1 --no-sandbox \2/' "${ROOTFS_DIRECTORY}"/usr/share/applications/chromium.desktop
		fi

		buffer -h3
		trap - INT
		cursor -u1
		msg -ts "${selected_browser} Browser${suffix} installed"
	else
		buffer -h5
		trap - INT
		cursor -u1
		msg -te "Failed to install ${selected_browser} Browser${suffix}"
	fi
}

name="22.04 LTS"
code_name=noble
release=20260217

DISTRO_NAME=Ubuntu
PROGRAM_NAME=$(basename "${0}")
DISTRO_REPOSITORY=termux-ubuntu
KERNEL_RELEASE=$(uname -r)
VERSION_NAME="${name} ${code_name}-${release}"

SHASUM_CMD=sha256sum
TRUSTED_SHASUMS=$(
	cat <<-EOF
		259da76864f8e9ede05c9530d59023616a9f7570738cec4d4245b1734fd51dfe *noble-server-cloudimg-arm64-root.tar.xz
		4f3d3ca84b2626065b0d1dbf2ca7d8b75b1962f1659c94aa1da98f02e913c628 *noble-server-cloudimg-armhf-root.tar.xz
	EOF
)

ARCHIVE_STRIP_DIRS=0 # directories stripped by tar when extracting rootfs archive
BASE_URL=https://cloud-images.ubuntu.com/${code_name}/${release}
TERMUX_FILES_DIR=/data/data/com.termux/files

DISTRO_SHORTCUT=${TERMUX_FILES_DIR}/usr/bin/ub
DISTRO_LAUNCHER=${TERMUX_FILES_DIR}/usr/bin/ubuntu

DEFAULT_ROOTFS_DIR=${TERMUX_FILES_DIR}/ubuntu
DEFAULT_LOGIN=root

# WARNING!!! DO NOT CHANGE BELOW!!!

# Check in program's directory for template
distro_template=$(realpath "$(dirname "${0}")")/termux-distro.sh

# shellcheck disable=SC1090
if [[ -f ${distro_template} ]] || curl -fsSLO https://raw.githubusercontent.com/jorexdeveloper/termux-distro/main/termux-distro.sh &>/dev/null; then
	source "${distro_template}" "${@}" || exit 1
else
	echo "You need an active internet connection to run this program."
fi
