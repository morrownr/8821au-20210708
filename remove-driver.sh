#!/bin/bash

# Purpose: Remove Realtek out-of-kernel USB WiFi adapter drivers.
#
# Supports dkms and non-dkms removals.

SCRIPT_NAME="remove-driver.sh"
SCRIPT_VERSION="20221101"
MODULE_NAME="8821au"
DRV_VERSION="5.12.5.2"
OPTIONS_FILE="${MODULE_NAME}.conf"

KVER="$(uname -r)"
KARCH="$(uname -m)"
KSRC="/lib/modules/${KVER}/build"
MODDESTDIR="/lib/modules/${KVER}/kernel/drivers/net/wireless/"

DRV_NAME="rtl${MODULE_NAME}"
DRV_DIR="$(pwd)"

# check to ensure sudo was used
if [[ $EUID -ne 0 ]]
then
	echo "You must run this script with superuser (root) privileges."
	echo "Try: \"sudo ./${SCRIPT_NAME}\""
	exit 1
fi

# support for the NoPrompt option allows non-interactive use of this script
NO_PROMPT=0

# get the script options
while [ $# -gt 0 ]
do
	case $1 in
		NoPrompt)
			NO_PROMPT=1 ;;
		*h|*help|*)
			echo "Syntax $0 <NoPrompt>"
			echo "       NoPrompt - noninteractive mode"
			echo "       -h|--help - Show help"
			exit 1
			;;
	esac
	shift
done

# displays script name and version
echo "Running ${SCRIPT_NAME} version ${SCRIPT_VERSION}"

# check for and remove non-dkms installation
if [[ -f "${MODDESTDIR}${MODULE_NAME}.ko" ]]
then
	echo "Removing a non-dkms installation."
	rm -f ${MODDESTDIR}${MODULE_NAME}.ko
	/sbin/depmod -a ${KVER}
fi

# information that helps with bug reports
# kernel
echo "Kernel=${KVER}"
# architecture - for ARM: aarch64 = 64 bit, armv7l = 32 bit
echo "Architecture=${KARCH}"
#getconf LONG_BIT (may be handy in the future)

#  2>/dev/null suppresses the output of dkms
dkms remove -m ${DRV_NAME} -v ${DRV_VERSION} --all 2>/dev/null
RESULT=$?
#echo "Result=${RESULT}"

# RESULT will be 3 if there are no instances of module to remove
# however we still need to remove various files or the install script
# may complain.
if [[ ("$RESULT" = "0")||("$RESULT" = "3") ]]
then
	if [[ ("$RESULT" = "0") ]]
	then
		echo "${DRV_NAME}/${DRV_VERSION} has been removed"
		echo "If older versions of ${DRV_NAME} are installed, run:"
		echo "$ sudo dkms remove ${DRV_NAME}/<version> --all"
		echo "dkms shows the following drivers are still installed:"
		dkms status
	fi
	echo "Removing ${BLACKLIST_FILE} from /etc/modprobe.d"
	rm -f /etc/modprobe.d/${BLACKLIST_FILE}
	echo "Removing ${OPTIONS_FILE} from /etc/modprobe.d"
	rm -f /etc/modprobe.d/${OPTIONS_FILE}
	echo "Removing source files from /usr/src/${DRV_NAME}-${DRV_VERSION}"
	rm -rf /usr/src/${DRV_NAME}-${DRV_VERSION}
	echo "The driver was removed successfully."
	echo "You may now delete the driver directory if desired."
else
	echo "An error occurred. dkms remove error = ${RESULT}"
	echo "Please report this error."
	exit $RESULT
fi

# if NoPrompt is not used, ask user some questions to complete removal
if [ $NO_PROMPT -ne 1 ]
then
	read -p "Do you want to reboot now? (recommended) [y/N] " -n 1 -r
	echo
	if [[ $REPLY =~ ^[Yy]$ ]]
	then
		reboot
	fi
fi

exit 0
