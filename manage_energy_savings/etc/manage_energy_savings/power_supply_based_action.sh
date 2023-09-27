#!/bin/bash

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin";

SCRIPT_DIR=$(dirname $0);
SCRIPT_NAME=$(basename $0);
DATE_TS=$(date +"%Y%m%d%H%M%S");
HOST=$(hostname);

PROGRAM_PID_FILE="$SCRIPT_DIR/$SCRIPT_NAME"".pid";
LAST_PROGRAM_PID="";
DELAY_TO_DETECT_RACE_CONDITION_SEC=1;

MAINS_POWER_SUPPLY_PATH="/sys/class/power_supply/AC*/online";
BATTERY_CAPACITY_LEVEL_PATH="/sys/class/power_supply/BAT*/capacity_level";
DEFAULT_POWER_SUPPLY="BATTERY";
DEFAULT_POWER_LEVEL="NORMAL";

# Check last running instance of the program has ended before continuing
if [[ -f "$PROGRAM_PID_FILE" ]]
then
	LAST_PROGRAM_PID=$(cat $PROGRAM_PID_FILE);
fi;

if [[ "$LAST_PROGRAM_PID" != "" ]]
then
	ps --pid "$LAST_PROGRAM_PID" &>/dev/null;
	
	if [[ $? -eq 0 ]]
	then
		echo "Another instance of the program with PID $LAST_PROGRAM_PID is already running. Quitting.";
		exit 1;
	fi;
fi;

# Store PID
echo "$$" > "$PROGRAM_PID_FILE";

# Sleep for few seconds to check for any race condition
sleep $DELAY_TO_DETECT_RACE_CONDITION_SEC;

# Check last stored PID is your PID to continue
LAST_PROGRAM_PID=$(cat $PROGRAM_PID_FILE);

if [[ "$LAST_PROGRAM_PID" != "" ]] && [[ "$$" != "$LAST_PROGRAM_PID" ]]
then
	echo "Another instance of the program with PID $LAST_PROGRAM_PID was trigerred too quickly, so will quit to avoid any race condition.";
	exit 1;
fi;

POWER_SUPPLY="$DEFAULT_POWER_SUPPLY";
POWER_LEVEL="$DEFAULT_POWER_LEVEL";

if grep "1" $MAINS_POWER_SUPPLY_PATH &>/dev/null
then
	POWER_SUPPLY="MAINS";
elif grep -i "NORMAL" $BATTERY_CAPACITY_LEVEL_PATH &>/dev/null
then
	POWER_LEVEL="NORMAL";
elif grep -i "LOW" $BATTERY_CAPACITY_LEVEL_PATH &>/dev/null
then
	POWER_LEVEL="LOW";
elif grep -i "CRITICAL" $BATTERY_CAPACITY_LEVEL_PATH &>/dev/null
then
	POWER_LEVEL="CRITICAL";
fi;

RUN_DIR="$SCRIPT_DIR/run.d";

while read EXEC_PROGRAM
do
	"$EXEC_PROGRAM" "$POWER_SUPPLY" "$POWER_LEVEL";
done < <(ls -1d "$RUN_DIR"/* 2>/dev/null);

# Clear PID
cat /dev/null > "$PROGRAM_PID_FILE";

exit 0;
