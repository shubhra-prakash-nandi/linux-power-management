#!/bin/bash

SCRIPT_DIR=`dirname "$0"`;
SCRIPT_NAME=`basename "$0"`;

DEV_BUS_TYPE="i2c";
SYSFS_DEV_BUS_PATH="/sys/bus/$DEV_BUS_TYPE";
SYSFS_DEV_SEARCH_PATH="$SYSFS_DEV_BUS_PATH/devices/*";

SYSFS_DEV_NAME_ATTR_RELATIVE_PATH="name";

SYSFS_DEV_DRIVER_RELATIVE_BIND_PATH="new_device";
SYSFS_DEV_DRIVER_RELATIVE_UNBIND_PATH="delete_device";

SYSFS_DEV_POWER_RELATIVE_PATH="power";
SYSFS_DEV_POWER_CONTROL_RELATIVE_PATH="$SYSFS_DEV_POWER_RELATIVE_PATH/control";
SYSFS_DEV_POWER_AUTOSUSPEND_DELAY_MS_RELATIVE_PATH="$SYSFS_DEV_POWER_RELATIVE_PATH/autosuspend_delay_ms";
SYSFS_DEV_POWER_WAKEUP_RELATIVE_PATH="$SYSFS_DEV_POWER_RELATIVE_PATH/wakeup";

DEV_PROPERTY_ATTR_RELATIVE_PATH="";
DEV_PROPERTY_ATTR_STATE="";
DEV_ID="";

function print_help
{
	echo "Usage: $SCRIPT_DIR/$SCRIPT_NAME [options] DEVICE-ID";
	echo "DEVICE-ID should be a valid device name or 'all' to act on all devices.";
}

while [[ "$1" != "" ]]
do
	case "$1" in
		--driver-bind)							DEV_PROPERTY_ATTR_RELATIVE_PATH="$SYSFS_DEV_DRIVER_RELATIVE_BIND_PATH"
																shift
																DRIVER_ID="$1"
																;;
		--driver-unbind)						DEV_PROPERTY_ATTR_RELATIVE_PATH="$SYSFS_DEV_DRIVER_RELATIVE_UNBIND_PATH"
																;;
		--power-control)						DEV_PROPERTY_ATTR_RELATIVE_PATH="$SYSFS_DEV_POWER_CONTROL_RELATIVE_PATH";
																shift
																DEV_PROPERTY_ATTR_STATE="$1";
																;;
		--power-autosuspend-delay-ms)		DEV_PROPERTY_ATTR_RELATIVE_PATH="$SYSFS_DEV_POWER_AUTOSUSPEND_DELAY_MS_RELATIVE_PATH";
																shift
																DEV_PROPERTY_ATTR_STATE="$1";
																;;
		--power-wakeup)							DEV_PROPERTY_ATTR_RELATIVE_PATH="$SYSFS_DEV_POWER_WAKEUP_RELATIVE_PATH";
																shift
																DEV_PROPERTY_ATTR_STATE="$1";
																;;
		*)													DEV_ID="$1"
																;;
	esac;
	
	shift;
done;

if [[ "$DEV_ID" = "all" ]]
then
	APPLY_ON_ALL_DEV="Y";
elif [[ "$DEV_ID" = "" ]]
then
	echo "DEVICE-ID argument is not valid. Quitting.";
	echo "";
	print_help;
	exit 1;
fi;

if [[ "$DEV_PROPERTY_ATTR_RELATIVE_PATH" = "$SYSFS_DEV_DRIVER_RELATIVE_BIND_PATH" ]]
then
	if [[ "$DRIVER_ID" != "" ]]
	then
		SYSFS_DEV_DRIVER_RELATIVE_BIND_PATH="../../drivers/$DRIVER_ID/new_device";
		DEV_PROPERTY_ATTR_RELATIVE_PATH="$SYSFS_DEV_DRIVER_RELATIVE_BIND_PATH";
	else
		echo "No driver name provided for binding, quitting.";
		exit 1;
	fi;
fi;

while read SYSFS_DEV_PATH
do
	if [[ -e "$SYSFS_DEV_PATH/$SYSFS_DEV_NAME_ATTR_RELATIVE_PATH" ]]
	then
		DEV_NAME=`tail -1 "$SYSFS_DEV_PATH/$SYSFS_DEV_NAME_ATTR_RELATIVE_PATH"`;
	else
		continue;
	fi;
	
	if [[ "$APPLY_ON_ALL_DEV" != "Y" ]]
	then
		if [[ "$DEV_ID" != "$DEV_NAME" ]]
		then
			continue;
		fi;
	fi;
	
	if [[ "$DEV_PROPERTY_ATTR_RELATIVE_PATH" = "$SYSFS_DEV_DRIVER_RELATIVE_BIND_PATH" ]] || [[ "$DEV_PROPERTY_ATTR_RELATIVE_PATH" = "$SYSFS_DEV_DRIVER_RELATIVE_UNBIND_PATH" ]]
	then
		DEV_LINK=`readlink "$SYSFS_DEV_PATH/device" | tail -1`;
		DEV_PROPERTY_ATTR_STATE=`basename "$DEV_LINK"`;
	fi;
	
	if [[ "$DEV_PROPERTY_ATTR_RELATIVE_PATH" != "" ]]
	then
		DEV_PROPERTY_ATTR_PATH="$SYSFS_DEV_PATH/$DEV_PROPERTY_ATTR_RELATIVE_PATH";
		
		if [[ -e "$DEV_PROPERTY_ATTR_PATH" ]] && [[ "$DEV_PROPERTY_ATTR_STATE" != "" ]]
		then
			CURR_DEV_PROPERTY_ATTR_STATE=`tail -1 "$DEV_PROPERTY_ATTR_PATH"`;
			
			if [[ "$DEV_PROPERTY_ATTR_STATE" != "$CURR_DEV_PROPERTY_ATTR_STATE" ]]
			then
				(cd `dirname "$DEV_PROPERTY_ATTR_PATH"`; echo "$DEV_PROPERTY_ATTR_STATE" > `basename "$DEV_PROPERTY_ATTR_PATH"`;)
			fi;
		fi;
	else
		echo "No valid option provided. Quitting.";
		exit 1;
	fi;
done < <(ls -d $SYSFS_DEV_SEARCH_PATH);
