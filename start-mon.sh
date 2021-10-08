#!/bin/bash

SCRIPT_NAME="start-mon.sh"
SCRIPT_VERSION="20211008"

# Simple script to start monitor mode on the provided wlan interface

# Check to ensure sudo was used
if [[ $EUID -ne 0 ]]
then
	echo "You must run this script with superuser (root) privileges."
	echo "Try: \"sudo ./${SCRIPT_NAME}\""
	exit 1
fi

clear
echo "Running ${SCRIPT_NAME} version ${SCRIPT_VERSION}"

# Set color definitions (https://en.wikipedia.org/wiki/ANSI_escape_code)
RED='\033[0;31m'
YELLOW='\033[0;33;1m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

iface0mon='wlan0mon'

interface=${1:-wlan0}

# Check if interface exists

ip link set $interface down
if [ $? -eq 0 ]
then
	ip link set $interface name $iface0mon
	iw $iface0mon set monitor control
	ip link set $iface0mon up
	iw dev
else
	echo -e "${RED}ERROR: ${YELLOW}Please provide an existing interface as parameter! ${NC}"
	echo -e "${NC}Usage: start-mon.sh [interface:wlan0] ${NC}"
	echo -e "${NC}Tips: check with ${CYAN}iw dev ${NC}which interfaces are available! ${NC}"
	exit 1
fi

exit 0
