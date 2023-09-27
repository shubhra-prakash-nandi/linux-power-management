#!/bin/bash
SCRIPT_DIR=$(dirname $0);
echo "Installing files from: "$SCRIPT_DIR;
cp -Rv $SCRIPT_DIR/lib/* /lib/;
chmod -v 0755 /lib/systemd/system-sleep/custom_manage_sleep;
