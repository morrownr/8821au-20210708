#!/bin/bash

SCRIPT_NAME="start-mon.sh"
SCRIPT_VERSION="20211010"

# Simple script to start and test monitor mode on the provided wlan interface
#
# Some parts of this script require the installation of aircrack-ng
#
# $ sudo apt install aircrack-ng

# Check to ensure sudo was used to start the script
if [[ $EUID -ne 0 ]]
then
	echo "You must run this script with superuser (root) privileges."
	echo "Try: \"sudo ./${SCRIPT_NAME}\""
	exit 1
fi

echo "Running ${SCRIPT_NAME} version ${SCRIPT_VERSION}"

# Set color definitions (https://en.wikipedia.org/wiki/ANSI_escape_code)
RED='\033[1;31m'
YELLOW='\033[0;33;1m'
GREEN='\033[1;32m'
CYAN='\033[1;36m'
NC='\033[0m'

# Changing the interface name is currently (2021-09-09) broken
#iface0mon=wlan0mon

# Default channel
chan=1

# Option 1: if you only have one wlan interface (automatic detection)
#iface0=`iw dev | grep 'Interface' | sed 's/Interface //'`

# Option 2: if you have more than one wlan interface (default wlan0)
iface0=${1:-wlan0}

# Check if iface0 exists
ip link set $iface0 down
if [ $? -eq 0 ]
then
# Do not rename the interface - this driver has a bug
#	ip link set $iface0 name $iface0mon

	iw $iface0 set monitor control
	ip link set $iface0 up

	iw dev

	# airodump-ng will display a list of detected access points and clients
	echo    # move to a new line
	read -p "Do you want to display a list of access points? [y/N] " -n 1 -r
	echo    # move to a new line
	if [[ $REPLY =~ ^[Yy]$ ]]
	then
		airodump-ng $iface0 --band ag --cswitch 1
	else
		exit 0
	fi

	# set channel
	read -p "Do you want to set the channel? [y/N] " -n 1 -r
	echo    # move to a new line
	if [[ $REPLY =~ ^[Yy]$ ]]
	then
		echo -e "What channel do you want to set?"
		read chan
		iw dev $iface0 set channel $chan
	else
		exit 0
	fi

	# aireplay-ng will test injection capability
	read -p "Do you want to test injection capability? [y/N] " -n 1 -r
	echo    # move to a new line
	if [[ $REPLY =~ ^[Yy]$ ]]
	then
		aireplay-ng --test $iface0
	else
		exit 0
	fi
else
	echo -e "${RED}ERROR: ${YELLOW}Please provide an existing interface as parameter! ${NC}"
	echo -e "${NC}Usage: ${CYAN}$ sudo ./start-mon.sh [interface:wlan0] ${NC}"
	echo -e "${NC}Tip:   ${CYAN}$ iw dev ${NC}(displays available interfaces) ${NC}"
	exit 1
fi

exit 0
