# Install Ubuntu in Termux

Script to install Ubuntu in Termux.

## Contents

- [Contents](#contents)
- [Features](#features)
- [Installation](#installation)
- [How to Login](#how-to-login)
  - [Login Information](#login-information)
- [How to Start a VNC Server](#how-to-start-a-vnc-server)
  - [How to Connect to the VNC Server](#how-to-connect-to-the-vnc-server)
- [How to Install a Desktop Environment](#how-to-install-a-desktop-environment)
- [How to Uninstall Ubuntu](#how-to-uninstall-ubuntu)
- [Bugs](#bugs)
- [License](#license)

## Features

 - Interactive Installation.
 - Color output (if supported).
 - Shows progress during extraction.
 - Install Ubuntu in custom directory.
 - Automatic configuration (i.e set root password).
 - Other optimizations and improvements.

## Installation

Download and execute the installer script (**install-ubuntu.sh**) or copy and paste below commands in **Termux**.

```
apt-get update -y && apt-get install wget -y && wget -O install-ubuntu.sh https://raw.githubusercontent.com/jorexdeveloper/termux-ubuntu/main/install-ubuntu.sh && bash install-ubuntu.sh
```

The program also displays help information with option `-h` or `--help` to guide you further.

## How to Login

After successful installation, run command `ub` or `ubuntu` to start Ubuntu.

### Login Information

| User/Login         | Password |
|--------------------|----------|
| root (super user)  | **root** |

## How to Start a VNC Server

Start Ubuntu and run command `vnc` to start the VNC server. The server will be started at localhost (`127.0.0.1`).

The program also displays help information with option `-h` or `--help` to guide you further.

#### Note: The **VNC server** and **Desktop Environment** may not be pre-installed. You can install them as shown [below](#how-to-install-a-desktop-environment).

### How to Connect to the VNC Server

After starting the VNC server, install [NetHunter KeX](https://store.nethunter.com/en/packages/com.offsec.nethunter.kex/), or a **VNC viewer** of your choice and login with below information. (Use current user name and **VNC password** which is set on first run of `vnc`)

| User  | Display  | Port | Address     |
|-------|----------|------|-------------|
| root  | :0       | 5900 | localhost:0 |
| other | :1       | 5901 | localhost:1 |

## How to Install a Desktop Environment

Copy and paste below commands in **Ubuntu**.

```
unminimize <<<"y" && apt install man sudo dbus-x11 tigervnc-standalone-server ubuntu-desktop-minimal
```

## How to Uninstall Ubuntu

To uninstall Ubuntu, copy and paste below commands in **Termux**. (replace `$HOME/ubuntu-{armhf,arm64}` with the directory where you installed the rootfs if custom directory was specified)

```
rm -rI $PREFIX/bin/ub $PREFIX/bin/ubuntu $HOME/ubuntu-{armhf,arm64}
```

## Bugs

Currently, there aren't any bugs **that i know about** but please let me know in the [issues section][i0] if you find any.

## License

```
    Copyright (C) 2023  Jore

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
```

[i0]: https://github.com/jorexdeveloper/termux-ubuntu/issues
