#!/bin/bash
SCRIPT_DIR=$(dirname $0);
echo "Installing files from: "$SCRIPT_DIR;
cp -Rv $SCRIPT_DIR/etc/* /etc/;

echo "Applying file ownership and permissions";
find "/etc/manage_devices" -type f -name "*.sh" -execdir chmod -v 0755 \{\} \;
