#!/bin/sh

#Test area

MYSELF=$(whoami)

if [ $(id -Gn "$MYSELF" | grep -c "i2c") -gt "0" ]; then
	echo "$MYSELF, I came up with more than 0, you're in the i2c group and good to go."
	exit
else
	echo "$MYSELF, I came up with 0, you're not in the i2c group.  Go away."
	exit
fi
