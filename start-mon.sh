#!/bin/bash

SCRIPT_NAME="start-mon.sh"
SCRIPT_VERSION="20211009"

# Simple script to start monitor mode on the provided wlan interface

# Check to ensure sudo was used
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

# Detect wlan interface name
iface0=`iw dev | grep 'Interface' | sed 's/Interface //'`

# iface0='wlan0mon'
# iface0=${1:-wlan0}

# Check if iface0 exists
ip link set $iface0 down
if [ $? -eq 0 ]
then
# Do not rename the interface - this driver has a bug
#	ip link set $interface name $iface0mon

	iw $iface0 set monitor control
	ip link set $iface0 up

	iw dev
else
	echo -e "${RED}ERROR: ${YELLOW}Please provide an existing interface as parameter! ${NC}"
	echo -e "${NC}Usage: ${CYAN}$ sudo ./start-mon.sh [interface:wlan0] ${NC}"
	echo -e "${NC}Tip:   ${CYAN}$ iw dev ${NC}(displays available interfaces) ${NC}"
	exit 1
fi

exit 0
