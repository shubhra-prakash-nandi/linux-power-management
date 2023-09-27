#!/bin/bash

SCRIPT_DIR=$(dirname "$0");
SCRIPT_NAME=$(basename "$0");

if [[ "$1" != "" ]]
then
	EXE_SCRIPT_DIR="$SCRIPT_DIR/run.d/$1";
else
	echo "$0: [ERROR] A valid run directory name must be provided as the first argument. Check valid directory names under '$SCRIPT_DIR/run.d'. Quitting.";
	exit 1;
fi;

if [[ -d "$EXE_SCRIPT_DIR" ]]
then
	while read EXE_SCRIPT
	do
		"$EXE_SCRIPT" "$2";
	done < <(ls -1d "$EXE_SCRIPT_DIR"/* 2>/dev/null);
else
	echo "$0: [ERROR] Directory '$EXE_SCRIPT_DIR' does not exist for selecting scripts to execute. Quitting.";
	exit 1;
fi;
