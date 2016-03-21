#!/bin/sh

###########################################################
#
#Battery Stats for the C.H.I.P.
# ***Original by CapnBry***
#
# ***v.2 by Herb_Tarlek***
#
###########################################################

BATTERY_FILE="batterystats3.txt"

# THIS PART IS NOT FINISHED YET
# check for i2c group
#
#
#
#if (id -Gn | grep -c "i2c") > "0"; then
#	MYSELF=$(whoami)
#	echo "You are not a member of the i2c group.\
#	Please execute 'sudo usermod -a -G i2c $MYSELF', logout and back in or reboot,\
#	and try again."
#	exit
#fi
#
#
#

# set ADC enabled for all channels
ADC=$(/usr/sbin/i2cget -y -f 0 0x34 0x82)
# if couldn't perform get, then exit immediately
[ $? -ne 0 ] && exit $?

if [ "$ADC" != "0xff" ] ; then
    /usr/sbin/i2cset -y -f 0 0x34 0x82 0xff
    # Need to wait at least 1/25s for the ADC to take a reading
    sleep 1
fi

while [ true ] ; do
    BAT_VOLT_MSB=$(/usr/sbin/i2cget -y -f 0 0x34 0x78)
    BAT_VOLT_LSB=$(/usr/sbin/i2cget -y -f 0 0x34 0x79)

    BAT_BIN=$(( ($BAT_VOLT_MSB << 4) | ($BAT_VOLT_LSB & 0x0F) ))
    BAT_VOLT=$(echo "$BAT_BIN*1.1"|bc)

    POWER_STATUS=$(/usr/sbin/i2cget -y -f 0 0x34 0x00)

    if [ $(($POWER_STATUS & 0x04)) -ne 0 ] ; then
      # Charging
      BAT_ICHG_MSB=$(/usr/sbin/i2cget -y -f 0 0x34 0x7A)
      BAT_ICHG_LSB=$(/usr/sbin/i2cget -y -f 0 0x34 0x7B)
      BAT_ICHG_BIN=$(( ($BAT_ICHG_MSB << 4) | ($BAT_ICHG_LSB & 0x0F) ))
    else
      # Discharging
      BAT_ICHG_MSB=$(/usr/sbin/i2cget -y -f 0 0x34 0x7C)
      BAT_ICHG_LSB=$(/usr/sbin/i2cget -y -f 0 0x34 0x7D)
      BAT_ICHG_BIN=$(( ($BAT_ICHG_MSB << 5) | ($BAT_ICHG_LSB & 0x1F) ))
    fi

    BAT_ICHG=$(echo "$BAT_ICHG_BIN*0.5"|bc)

    X="$BAT_VOLT mV, $BAT_ICHG mA"
    CURRENT_TIME=$(date +"%H:%M:%S")
    BATTERY_CSV="$CURRENT_TIME,$BAT_VOLT,$BAT_ICHG"

    echo $X
    echo $BATTERY_CSV >> $BATTERY_FILE

# wait 5 seconds
    sleep 5
done
