#!/data/data/com.termux/files/usr/bin/bash

################################################################################
#                                                                              #
#     Ubuntu Installer, version 1.0                                            #
#                                                                              #
#     Install Ubuntu in Termux.                                                #
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

################################################################################
#                                FUNCTIONS                                     #
################################################################################

#########
### Major
#########

# Prints banner
function _BANNER() {
	clear
	printf "${C}┌──────────────────────────────────────────┐${N}\n"
	printf "${C}│${G} _   _  ____   _   _  _   _  _____  _   _ ${C}│${N}\n"
	printf "${C}│${G}| | | || __ ) | | | || \ | ||_   _|| | | |${C}│${N}\n"
	printf "${C}│${G}| | | ||  _ \ | | | ||  \| |  | |  | | | |${C}│${N}\n"
	printf "${C}│${G}| |_| || |_) || |_| || |\  |  | |  | |_| |${C}│${N}\n"
	printf "${C}│${G} \___/ |____/  \___/ |_| \_|  |_|   \___/ ${C}│${N}\n"
	printf "${C}│${Y}                 TERMUX                   ${C}│${N}\n"
	printf "${C}└──────────────────────────────────────────┘${N}\n"
	_PRINT_MSG "Version  ${SCRIPT_VERSION}" N
	_PRINT_MSG "Author   ${AUTHOR_NAME}" N
	_PRINT_MSG "Source   ${U}${AUTHOR_GITHUB}/${SCRIPT_REPOSITORY}${NU}" N
}

# Checks system architecture
# Sets SYS_ARCH LIB_GCC_PATH
function _CHECK_ARCHITECTURE() {
	_PRINT_TITLE "Checking device architecture"
	if local arch="$(getprop ro.product.cpu.abi 2>/dev/null)"; then
		case "${arch}" in
			arm64-v8a)
				SYS_ARCH="arm64"
				LIB_GCC_PATH="/usr/lib/aarch64-linux-gnu/libgcc_s.so.1"
				;;
			armeabi | armeabi-v7a)
				SYS_ARCH="armhf"
				LIB_GCC_PATH="/usr/lib/arm-linux-gnueabihf/libgcc_s.so.1"
				;;
			*)
				_PRINT_CRITICAL_ERROR "Unsupported architecture"
				;;
		esac
		_PRINT_MSG "${arch} is supported"
	else
		_PRINT_CRITICAL_ERROR "Failed to get device architecture"
	fi
}

# Che<ks for required dependencies
function _CHECK_DEPENDENCIES() {
	_PRINT_TITLE "Updating system"
	# Workaround for termux-app issue #1283 (https://github.com/termux/termux-app/issues/1283)
	apt-get -qq -o=Dpkg::Use-Pty=0 update -y 2>/dev/null || apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confnew" dist-upgrade -y 2>/dev/null || _PRINT_CRITICAL_ERROR "Failed to update system"
	_PRINT_MSG "System update complete"
	_PRINT_TITLE "Checking for package dependencies"
	for package in wget proot tar pulseaudio; do
		if [ -e "${PREFIX}/bin/${package}" ]; then
			_PRINT_MSG "Package ${package} is installed"
		else
			_PRINT_MSG "Installing ${package}" N
			apt-get -qq -o=Dpkg::Use-Pty=0 install -y "${package}" 2>/dev/null || _PRINT_CRITICAL_ERROR "Failed to install ${package}" 1
		fi
	done
}

# Checks foor existing ROOTFS_DIR
# Sets KEEP_ROOTFS_DIR
function _CHECK_ROOTFS_DIR() {
	unset KEEP_ROOTFS_DIR
	if [ -d "${ROOTFS_DIR}" ]; then
		if _ASK "Existing rootfs directory found. Delete and create a new one" "N"; then
			_PRINT_MSG "Deleting rootfs directory" E
		elif _ASK "Rootfs directory might be corrupt, use it anyway" "N"; then
			_PRINT_MSG "Using existing rootfs directory"
			KEEP_ROOTFS_DIR=1
			return
		else
			_PRINT_CRITICAL_ERROR "Rootfs directory not touched"
		fi
	elif [ -e "${ROOTFS_DIR}" ]; then
		if _ASK "Unknown item found with same name as rootfs directory. Delete item" "N"; then
			_PRINT_MSG "Deleting unknown item" E
		else
			_PRINT_CRITICAL_ERROR "Unknown item not touched"
		fi
	fi
	rm -rf "${ROOTFS_DIR}"
}

# Downloads roots archive
# Sets KEEP_ROOTFS_MAGE
function _DOWNLOAD_ROOTFS_ARCHIVE() {
	unset KEEP_ROOTFS_MAGE
	if [ -z "${KEEP_ROOTFS_DIR}" ]; then
		if [ -f "${ARCHIVE_NAME}" ]; then
			if _ASK "Existing roots archive found. Delete and download a new one" "N"; then
				_PRINT_MSG "Deleting old roots archive" E
			else
				_PRINT_MSG "Using existing rootfs archive"
				KEEP_ROOTFS_MAGE=1
				return
			fi
		elif [ -e "${ARCHIVE_NAME}" ]; then
			if _ASK "Unknown item found with same name as rootfs archive. Delete item" "N"; then
				_PRINT_MSG "Deleting unknown item" E
			else
				_PRINT_CRITICAL_ERROR "Unknown item not touched"
			fi
		fi
		rm -f "${ARCHIVE_NAME}"
		_PRINT_TITLE "Downloading rootfs archive"
		wget --no-verbose --continue --show-progress --output-document="${ARCHIVE_NAME}" "${BASE_URL}/${ARCHIVE_NAME}" || _PRINT_CRITICAL_ERROR "Failed to download rootfs archive" 1
	fi
}

# Verifies integrity of rootfs archive
function _VERIFY_ROOTFS_ARCHIVE() {
	if [ -z "${KEEP_ROOTFS_DIR}" ]; then
		_PRINT_TITLE "Verifying integrity of the rootfs archive"
		local TRUSTED_SHASUMS=(
			"8deb8c185e66c0a7aea45ffa70000d609b0269e23a7af8433398486edfa81910 *ubuntu-kinetic-core-cloudimg-armhf-root.tar.gz"
			"a851c717d90610d3e9528c35a26fdc40a7111c069d7a923ab094c6fcf0b7b5f6 *ubuntu-kinetic-core-cloudimg-arm64-root.tar.gz"
			"639dc3b4617c3e9cf809d68d0b8df72d64233dba030d0750786ef7bd67d29b92 *ubuntu-kinetic-core-cloudimg-armhf.manifest"
			"5411524946322b60e658df304eeae33dec5418072189f5c09be50cf0eb926363 *ubuntu-kinetic-core-cloudimg-arm64.manifest"
		)
		if echo "${TRUSTED_SHASUMS}" | grep -e "${ARCHIVE_NAME}" | sha256sum --check &>/dev/null; then
			_PRINT_MSG "Rootfs archive is ok"
			return
		elif TRUSTED_SHASUMS="$(wget --quiet --output-document="-" "${BASE_URL}/SHA256SUMS")"; then
			if echo "${TRUSTED_SHASUMS}" | grep -e "${ARCHIVE_NAME}" | sha256sum --check &>/dev/null; then
				_PRINT_MSG "Rootfs archive is ok"
				return
			fi
		else
			_PRINT_CRITICAL_ERROR "Failed to verify integrity of the rootfs archive" 1
		fi
		_PRINT_CRITICAL_ERROR "Rootfs corrupted" 0
	fi
}

# Extracts rootfs archive
function _EXTRACT_ROOTFS() {
	if [ -z "${KEEP_ROOTFS_DIR}" ]; then
		_PRINT_TITLE "Extracting rootfs archive"
		local tmp_xtract_dir="${TMPDIR}/${DEFAULT_ROOTFS_DIR}"
		if [ -e "${tmp_xtract_dir}" ]; then
			rm -rf "${tmp_xtract_dir}"
		fi
		mkdir -p "${tmp_xtract_dir}"
		printf "${G}"
		proot --link2symlink tar --extract --file="${ARCHIVE_NAME}" --directory="${tmp_xtract_dir}" --checkpoint=1 --checkpoint-action=ttyout="   Files extracted %{}T in %ds%*\r" &>/dev/null || _PRINT_CRITICAL_ERROR "Failed to extract rootfs archive" 0
		printf "${N}"
		if [ -d "${tmp_xtract_dir}" ]; then
			if [ -e "${ROOTFS_DIR}" ]; then
				rm -rf "${ROOTFS_DIR}"
			fi
			mv "${tmp_xtract_dir}" "${ROOTFS_DIR}" && _PRINT_MSG "Extraction complete" || _PRINT_CRITICAL_ERROR "Fatal extraction error" 0
		else
			_PRINT_CRITICAL_ERROR "Fatal extraction error" 0
		fi
	fi
}

# Creates a script to start Ubuntu
function _CREATE_LAUNCHER() {
	_PRINT_TITLE "Creating Ubuntu launcher"
	local UBUNTU_LAUNCHER="${PREFIX}/bin/ubuntu"
	mkdir -p "${PREFIX}/bin" && cat >"${UBUNTU_LAUNCHER}" <<-EOF
		#!/data/data/com.termux/files/usr/bin/bash -e

		################################################################################
		#                                                                              #
		#     Ubuntu launcher, version ${SCRIPT_VERSION}                                             #
		#                                                                              #
		#     This script starts Ubuntu.                                               #
		#                                                                              #
		#     Copyright (C) 2023  ${AUTHOR_NAME} <${AUTHOR_GITHUB}>            #
		#                                                                              #
		################################################################################

		# Enables audio support
		# For rooted users, add option '--system'
		pulseaudio --start --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" --exit-idle-time=-1

		# unset LD_PRELOAD in case termux-exec is installed
		unset LD_PRELOAD

		# Workaround for Libreoffice, also needs to bind a fake /proc/version
		if [ ! -f "${ROOTFS_DIR}/root/.version" ]; then
		    touch "${ROOTFS_DIR}/root/.version"
		fi

		# Command to start Ubuntu
		command="proot \\
		         --link2symlink \\
		         --kill-on-exit \\
		         --root-id \\
		         --rootfs=${ROOTFS_DIR} \\
		         --bind=/dev \\
		         --bind=/proc \\
		         --bind=${ROOTFS_DIR}/root:/dev/shm \\
		         --bind=\$([ ! -z "\${INTERNAL_STORAGE}" ] && echo "\${INTERNAL_STORAGE}" || echo "/sdcard"):/media/disk0 \\
		         --bind=\$([ ! -z "\${EXTERNAL_STORAGE}" ] && echo "\${EXTERNAL_STORAGE}" || echo "/sdcard"):/media/disk1 \\
		         --cwd=/ \\
		            /usr/bin/env -i \\
		            TERM=\${TERM} \\
		            LANG=C.UTF-8 \\
		            /usr/bin/login
		         "

		# Execute launch command
		exec \${command}
	EOF
	termux-fix-shebang "${UBUNTU_LAUNCHER}" && chmod 700 "${UBUNTU_LAUNCHER}" || _PRINT_CRITICAL_ERROR "Failed to create Ubuntu launcher" 0
	_PRINT_MSG "Ubuntu launcher created successfully"
}

# Creates a script to start the VNC server in Ubuntu
function _CREATE_VNC_LAUNCHER() {
	_PRINT_TITLE "Creating VNC launcher"
	local VNC_LAUNCHER="${ROOTFS_DIR}/usr/local/bin/vnc"
	mkdir -p "${ROOTFS_DIR}/usr/local/bin" && cat >"${VNC_LAUNCHER}" <<-EOF
		#!/bin/bash -e
		################################################################################
		#                                                                              #
		#     VNC launcher, version ${SCRIPT_VERSION}                                                #
		#                                                                              #
		#     This script starts the VNC server.                                       #
		#                                                                              #
		#     Copyright (C) 2023  ${AUTHOR_NAME} <${AUTHOR_GITHUB}>            #
		#                                                                              #
		################################################################################

		depth=24
		width=720
		height=1600
		orientation=landscape
		display=\$(echo \${DISPLAY} | cut -d : -f 2)

		function check_user() {
		    if [ "\${USER}" = "root" ] || [ "\$EUID" -eq 0 ] || [ "\$(whoami)" = "root" ]; then
		        read -p "[!] Warning: You are starting VNC as root user, some applications are not meant to be run as root and may not work properly. Do you want to continue? y/N" -rn 1 REPLY && echo && case "\${REPLY}" in y|Y) ;; *) exit 1 ;; esac
		    fi
		}

		function clean_tmp() {
		    rm -rf "/tmp/.X\${display}-lock"
		    rm -rf "/tmp/.X11-unix/X\${display}"
		}

		function set_geometry() {
		    case "\$orientation" in
		        "potrait")
		            geometry="\${width}x\${height}"
		            ;;
		        *)
		            geometry="\${height}x\${width}"
		            ;;
		    esac
		}

		function start_pulseaudio() {
		    if [ -f "/bin/pulseaudio" ] || ! which pulseaudio &>/dev/null; then
		        pulseaudio --start --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" --exit-idle-time=-1
		    else
		        echo "[!] Pulse Audio not installed, you may not get audio output."
		    fi
		}

		function set_passwd() {
		    vncpasswd
		    return \$?
		}

		function start_server() {
		    if [ -f "\${HOME}/.vnc/passwd" ]; then
		        export HOME="\${HOME}"
		        export USER="\${USER}"
		        LD_PRELOAD="${LIB_GCC_PATH}"
		        # You can use nohup
		        vncserver ":\$display" -geometry "\$geometry" -depth "\$depth" -name remote-desktop && echo -e "\n[*] VNC Server started successfully."
		    else
		        set_passwd && start_server
		    fi
		}

		function kill_server() {
		    # [ -f "/bin/pulseaudio" ] && pulseaudio --kill || pkill -9 pulseaudio
		    clean_tmp
		    vncserver -clean -kill ":\$display"
		    return \$?
		}

		function print_help() {
		    printf "Usage: \$(basename $0) [option]...\n\n"
		    printf "Start VNC Server.\n\n"
		    printf "Options:\n"
		    printf "  --potrait\n"
		    printf "          Use potrait orientation.\n"
		    printf "  --landscape\n"
		    printf "          Use landscape orientation. (default)\n"
		    printf "  -p, --password\n"
		    printf "          Set or change password.\n"
		    printf "  -s, --start\n"
		    printf "          Start vncserver. (default if no options supplied)\n"
		    printf "  -k, --kill\n"
		    printf "          Kill vncserver.\n"
		    printf "  -h, --help\n"
		    printf "          Print this message and exit.\n"
		}

		############################################
		##               Entry Point              ##
		############################################

		for option in \$@; do
		    case \$option in
		        "--potrait")
		            orientation=potrait
		            ;;
		        "--landscape")
		            orientation=landscape
		            ;;
		        "-p"|"--password")
		            set_passwd
		            exit
		            ;;
		        "-s"|"--start")
		            ;;
		        "-k"|"--kill")
		            kill_server
		            exit
		            ;;
		        "-h"|"--help")
		            _PRINT_USAGE
		            exit
		            ;;
		        *)
		            echo "Unknown option '\$option'."
		            print_help
		            exit 1
		            ;;
		    esac
		done
		check_user && clean_tmp && set_geometry && start_server
	EOF
	chmod 700 "$VNC_LAUNCHER" || _PRINT_CRITICAL_ERROR "Failed to create VNC launcher" 0
}

# Prompts whether to delete downloaded files
function _CLEANUP_DOWNLOADS() {
	if [ -z "${KEEP_ROOTFS_DIR}" ] && [ -z "${KEEP_ROOTFS_MAGE}" ] && [ -f "${ARCHIVE_NAME}" ]; then
		if _ASK "Remove downloaded rootfs archive to save space" "N"; then
			_PRINT_MSG "Removing downloaded rootfs archive" E
			rm -f "${ARCHIVE_NAME}" || _PRINT_MSG "Failed to remove downloaded rootfs archive" E
		else
			_PRINT_MSG "Downloaded rootfs archive not touched"
		fi
	fi
}

# Prints usage instructions
function _PRINT_COMPLETE_MSG() {
	_PRINT_TITLE "Ubuntu installed successfully" S
	_PRINT_MSG "Run command '${Y}ubuntu${C}' to start Ubuntu" N
	_PRINT_MSG "Run command '${Y}vnc${C}' in Ubuntu to start the VNC Server" N
	_PRINT_TITLE "Login Information"
	_PRINT_MSG "User/Login  ${Y}root${G}"
	_PRINT_MSG "Password    ${Y}${ROOT_PASSWD}${N}${G}"
	_PRINT_TITLE "Documentation  ${U}${AUTHOR_GITHUB}/${SCRIPT_REPOSITORY}${NU}"
	# Message prompt for minimal and nano installations
	_PRINT_TITLE "This is a minimal installation of Ubuntu" E
	_PRINT_MSG "Read the documentation on how to install additional components" E
}

# Prints script version
function _PRINT_VERSION() {
	_PRINT_TITLE "Ubuntu Installer, version ${SCRIPT_VERSION}"
	_PRINT_MSG "Copyright (C) 2023 ${AUTHOR_NAME} <${U}${AUTHOR_GITHUB}${NU}>"
	_PRINT_MSG "License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>"
	_PRINT_MSG "This is free software; you are free to change and redistribute it"
	_PRINT_MSG "There is NO WARRANTY, to the extent permitted by law"
}

# Prints script usage
function _PRINT_USAGE() {
	_PRINT_TITLE "Usage  $(basename "$0") [option${C}]... [DIRECTORY]"
	_PRINT_MSG "Install Ubuntu in DIRECTORY (default HOME/${DEFAULT_ROOTFS_DIR})"
	_PRINT_TITLE "Options"
	_PRINT_MSG "-h, --help"
	_PRINT_MSG "        Print this message and exit"
	_PRINT_MSG "-v. --version"
	_PRINT_MSG "        Print program version and exit"
	_PRINT_TITLE "DIRECTORY must be within ${TERMUX_FILES_DIR} or its sub-folders" E
	_PRINT_TITLE "Documentation  ${U}${AUTHOR_GITHUB}/${SCRIPT_REPOSITORY}${NU}"
}

##########
### Issues
##########

# Fixes all issues
# Sets TMP_LOGIN_COMMAND
function _FIX_ISSUES() {
	_PRINT_TITLE "Installation complete"
	_PRINT_MSG "Making some tweaks"
	local bug_descriptions=(
		"Configuring sudo and su"
		"Setting a password for root"
		"Setting display values"
		"Settting host information"
		"Settting pulse audio server"
		"Setting java variables"
		"Setting DNS information"
	)
	unset LD_PRELOAD && TMP_LOGIN_COMMAND="proot --link2symlink --root-id --rootfs=${ROOTFS_DIR} --cwd=/"
	local descr_num=0
	for issue in _FIX_SUDO _FIX_ROOT_PASSWD _FIX_DISPLAY _FIX_HOSTS _FIX_AUDIO _FIX_JDK _FIX_DNS; do
		_PRINT_MSG "${bug_descriptions[${descr_num}]}" N
		if "${issue}" &>/dev/null; then
			_PRINT_MSG "Done"
		else
			_PRINT_MSG "Failed" E
		fi
		((descr_num++))
	done
}

# Fixes sudo and su on start
function _FIX_SUDO() {
	local bin_dir="${ROOTFS_DIR}/usr/bin"
	if [ -f "${bin_dir}/sudo" ]; then
		chmod +s "${bin_dir}/sudo"
	fi
	if [ -f "${bin_dir}/su" ]; then
		chmod +s "${bin_dir}/su"
	fi
	echo "Set disable_coredump false" >"${ROOTFS_DIR}/etc/sudo.conf"
}

# Sets a passwd for root user
function _FIX_ROOT_PASSWD() {
	if [ -f "${ROOTFS_DIR}/usr/bin/passwd" ]; then
		${TMP_LOGIN_COMMAND} "usr/bin/passwd" root <<-EOF
			${ROOT_PASSWD}
			${ROOT_PASSWD}
		EOF
	else
		_PRINT_CRITICAL_ERROR "Failed to set password for root" 0
	fi
}

# Sets display for Ubuntu
function _FIX_DISPLAY() {
	cat >"${ROOTFS_DIR}/etc/profile.d/display.sh" <<-EOF
		if [ "\${USER}" = "root" ] || [ "\$EUID" -eq 0 ] || [ "\$(whoami)" = "root" ]; then
		    export DISPLAY=:0
		else
		    export DISPLAY=:1
		fi
	EOF
}

# Sets host information
function _FIX_HOSTS() {
	echo "ubuntu" >"${ROOTFS_DIR}/etc/hostname"
	cat >"${ROOTFS_DIR}/etc/hosts" <<-EOF
		127.0.0.1       localhost
		127.0.1.1       ubuntu
	EOF
}

# Sets the pulse audio server
function _FIX_AUDIO() {
	echo "export PULSE_SERVER=127.0.0.1" >"${ROOTFS_DIR}/etc/profile.d/pulseserver.sh"
}

# Sets java variables
function _FIX_JDK() {
	if [[ "${SYS_ARCH}" == "armhf" ]]; then
		cat >"${ROOTFS_DIR}/etc/profile.d/java.sh" <<-EOF
			export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-armhf/
			export PATH=\$JAVA_HOME/bin:\$PATH
		EOF
	elif [[ "${SYS_ARCH}" == "arm64" ]]; then
		cat >"${ROOTFS_DIR}/etc/profile.d/java.sh" <<-EOF
			export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-aarch64/
			export PATH=\$JAVA_HOME/bin:\$PATH
		EOF
	else
		return 1
	fi
}

# Sets dns settings
function _FIX_DNS() {
	cat >"${ROOTFS_DIR}/etc/resolv.conf" <<-EOF
		nameserver 8.8.8.8
		nameserver 8.8.4.4
	EOF
}

###########
### Helpers
###########

# Prints title
function _PRINT_TITLE() {
	local color="${C}"
	local prefix=">>"
	case "${2}" in
		s | S)
			color="${G}"
			# prefix=" "
			;;
		e | E)
			color="${R}"
			# prefix=" "
			;;
	esac
	printf "\n${color}${prefix} ${1}.${N}\n"
}

# Prints message
function _PRINT_MSG() {
	local color="${G}"
	local prefix=" "
	case "${2}" in
		n | N)
			color="${C}"
			# prefix=" "
			;;
		e | E)
			color="${R}"
			# prefix=" "
			;;
	esac
	printf "${color} ${prefix} ${1}.${N}\n"
}

# Prints error message and exits
function _PRINT_CRITICAL_ERROR() {
	local color="${R}"
	local prefix=" "
	if [ -n "${2}" ]; then
		local suggested_messages=(
			" Try executing this script again."
			" Internet connection required."
		)
		local message="${suggested_messages[${2}]}"
	fi
	printf "${color} ${prefix} ${1}.${message}${N}\n"
	exit 1
}

# Asks for Y/N response
function _ASK() {
	local color="${C}"
	local prefix=" "
	if [ "${2:-}" = "Y" ]; then
		local prompt="Y/n"
		local default="Y"
	elif [ "${2:-}" = "N" ]; then
		local prompt="y/N"
		local default="N"
	else
		local prompt="y/n"
		local default=""
	fi
	# printf "\n"
	local retries=3
	while true; do
		if [ ${retries} -ne 3 ]; then
			prefix="${retries}"
		fi
		printf "\r${color} ${prefix} ${1}? ${prompt} ${N}"
		read -rn 1 reply
		if [ -z "${reply}" ]; then
			reply="${default}"
		fi
		case "${reply}" in
			Y | y) unset reply && printf "\n" && return 0 ;;
			N | n) unset reply && printf "\n" && return 1 ;;
		esac
		# Ask and return 3rd time if default value is set
		((retries--))
		if [ -n "${default}" ] && [ ${retries} -eq 0 ]; then # && [[ ${default} =~ ^(Y|N|y|n)$ ]]; then
			case "${default}" in
				y | Y) unset reply && printf "\n" && return 0 ;;
				n | N) unset reply && printf "\n" && return 1 ;;
			esac
		fi
	done
}

################################################################################
#                                ENTRY POINT                                   #
################################################################################

# Author info
AUTHOR_NAME="Jore"
AUTHOR_GITHUB="https://github.com/jorexdeveloper"

# Script info
SCRIPT_REPOSITORY="Install-Ubuntu-Termux"
SCRIPT_VERSION="1.0"

# Static info
TERMUX_FILES_DIR="/data/data/com.termux/files"
DEFAULT_ROOTFS_DIR="ubuntufs"

case "${TERM}" in
	xterm-color | *-256color)
		R="\e[1;31m"
		G="\e[1;32m"
		Y="\e[1;33m"
		C="\e[1;36m"
		U="\e[1;4m"
		NU="\e[24m"
		N="\e[0m"
		;;
esac

# Proces command line args
for option in "$@"; do
	case "${option}" in
		"-v" | "--version")
			_PRINT_VERSION
			exit
			;;
		"-h" | "--help")
			_PRINT_USAGE
			exit
			;;
	esac
done

# Customizable info
ROOT_PASSWD="root"
CODE_NAME="kinetic"
BASE_URL="https://partner-images.canonical.com/core/${CODE_NAME}/current"

# Print banner
_BANNER

# Check for support
_CHECK_ARCHITECTURE
_CHECK_DEPENDENCIES

# Set download file names
ARCHIVE_NAME="ubuntu-${CODE_NAME}-core-cloudimg-${SYS_ARCH}-root.tar.gz"
MANIFEST_NAME="ubuntu-${CODE_NAME}-core-cloudimg-${SYS_ARCH}.manifest"

# Set installation directory, but it must be within Termux to prevent file permission issues
if [ -n "$1" ] && ROOTFS_DIR="$(realpath "$1")" && [[ "${ROOTFS_DIR}" == "${TERMUX_FILES_DIR}"* ]]; then
	test
else
	# Set the directory explicitly in case user's home directory is modified
	ROOTFS_DIR="$(realpath "${TERMUX_FILES_DIR}/home/${DEFAULT_ROOTFS_DIR}")"
fi
_PRINT_TITLE "Installing Ubuntu in ${ROOTFS_DIR}"

# Installation
_CHECK_ROOTFS_DIR
_DOWNLOAD_ROOTFS_ARCHIVE
_VERIFY_ROOTFS_ARCHIVE
_EXTRACT_ROOTFS
_CREATE_LAUNCHER
_CREATE_VNC_LAUNCHER
_CLEANUP_DOWNLOADS

# Fix issues
_FIX_ISSUES

# Print help info
_PRINT_COMPLETE_MSG
