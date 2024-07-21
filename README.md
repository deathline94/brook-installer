# Brook Installer

Welcome to the Brook Installer script repository. This script provides a one-click solution to install, configure, modify, and uninstall the Brook VPN protocol on your Linux server.

## Introduction

Brook is a lightweight, efficient VPN software that supports various protocols. This script automates the installation and management of the Brook server on a Linux machine.

## Features

- One-click installation of Brook server
- Automated configuration with user-defined or random port and password
- Modify existing configuration with ease
- Uninstall Brook server and clean up all related files
- Service management with systemd for reliable start/stop operations

## Installation

To install Brook using this script, run the following command:

```sh
bash <(curl -fsSL https://raw.githubusercontent.com/deathline94/brook-installer/main/brook.sh)
