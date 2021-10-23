#!/bin/bash

SCRIPT_NAME="start-mon.sh"
SCRIPT_VERSION="20211019"

# Purpose: Start and test monitor mode on the provided wlan interface

# Some parts of this script require the installation of aircrack-ng
#
# $ sudo apt install aircrack-ng

# Interfering processes must be disabled for the provided interface
#
# Option 1
#```
# $ sudo airmon-ng check kill
#```
#
# Option 2, another way that works for me on Linux Mint:
#
# Note: I use multiple wifi adapters in my systems and I need to stay connected
# to the internet while testing. This option works well for me and allows
# me to stay connected by allowing Network Manager to continue managing interfaces
# that are not marked as unmanaged.
#
# Ensure Network Manager doesn't cause problems
#```
# $ sudo nano /etc/NetworkManager/NetworkManager.conf
#```
# add
#```
# [keyfile]
# unmanaged-devices=interface-name:<wlan0>;interface-name:wlan0mon
#```
#
# Note: The above tells Network Manager to leave the specified interfaces alone.

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

# Assign name to monitor mode interface
iface0mon='wlan0mon'

# Default channel
chan=1

# Activate one of the options below to set automatic or manual interface mode
#
# Option 1: if you only have one wlan interface (automatic detection)
#iface0=`iw dev | grep 'Interface' | sed 's/Interface //'`
#
# Option 2: if you have more than one wlan interface (default wlan0)
iface0=${1:-wlan0}

# Set iface0 down
ip link set $iface0 down
# Check if iface0 exists and continue if true
if [ $? -eq 0 ]
then
# 	Rename the interface
	read -p "Do you want to rename $iface0 to wlan0mon? [y/N] " -n 1 -r
	echo    # move to a new line
	if [[ $REPLY =~ ^[Yy]$ ]]
	then
		ip link set $iface0 name $iface0mon
	else
		iface0mon=$iface0
	fi

#	Set monitor mode
#	iw dev <devname> set monitor <flag>*
#		Set monitor flags. Valid flags are:
#		none:     no special flags
#		fcsfail:  show frames with FCS errors
#		control:  show control frames
#		otherbss: show frames from other BSSes
#		cook:     use cooked mode
#		active:   use active mode (ACK incoming unicast packets)
#		mumimo-groupid <GROUP_ID>: use MUMIMO according to a group id
#		mumimo-follow-mac <MAC_ADDRESS>: use MUMIMO according to a MAC address
	iw dev $iface0mon set monitor control

# 	Set iface0 up
	ip link set $iface0mon up

#	Display settings
	iw dev

#	Run airodump-ng
#	airodump-ng will display a list of detected access points and clients
#	https://www.aircrack-ng.org/doku.php?id=airodump-ng
#	https://en.wikipedia.org/wiki/Regular_expression
	echo    # move to a new line
	echo -e "airodump-ng can receive and interpret key strokes while running"
	echo    # move to a new line
	echo -e "a - select active areas"
	echo -e "s - change sort column"
	echo -e "q - quit"
	echo    # move to a new line
	read -p "Do you want to run airodump-ng to display a list of detected access points and clients? [y/N] " -n 1 -r
	echo    # move to a new line
	if [[ $REPLY =~ ^[Yy]$ ]]
	then

#		 usage: airodump-ng <options> <interface>[,<interface>,...]
#
#		  -c <channels>        : Capture on specific channels
#		  -a                   : Filter unassociated clients
#		 --ignore-negative-one : Removes the message that says fixed channel <interface>: -1
#		 --essid-regex <regex> : Filter APs by ESSID using a regular expression
#
#		shows hidden ESSIDs
#		airodump-ng -c 1-165 -a --ignore-negative-one $iface0mon
#
#		does not show hidden ESSIDs
		airodump-ng -c 1-165 -a --ignore-negative-one --essid-regex '^(?=.)^(?!.*CoxWiFi)' $iface0mon

	else
		exit 0
	fi

#	Set channel
	read -p "Do you want to set the channel? [y/N] " -n 1 -r
	echo    # move to a new line
	if [[ $REPLY =~ ^[Yy]$ ]]
	then
		echo -e "What channel do you want to set?"
		read chan
		iw dev $iface0mon set channel $chan
	else
		exit 0
	fi

#	Test injection capability with aireplay-ng
	read -p "Do you want to test injection capability? [y/N] " -n 1 -r
	echo    # move to a new line
	if [[ $REPLY =~ ^[Yy]$ ]]
	then
		aireplay-ng --test $iface0mon
	else
		exit 0
	fi

#	Return the adapter to managed mode
	read -p "Do you want to return the adapter to managed mode? [y/N] " -n 1 -r
	echo    # move to a new line
	if [[ $REPLY =~ ^[Yy]$ ]]
	then
		ip link set $iface0mon down
		ip link set $iface0mon name $iface0
		iw $iface0 set type managed
		iw dev
	else
		iw dev
		exit 0
	fi

else
	echo -e "${RED}ERROR: ${YELLOW}Please provide an existing interface as parameter! ${NC}"
	echo -e "${NC}Usage: ${CYAN}$ sudo ./start-mon.sh [interface:wlan0] ${NC}"
	echo -e "${NC}Tip:   ${CYAN}$ iw dev ${NC}(displays available interfaces) ${NC}"
	exit 1
fi

exit 0
