#!/bin/sh

# INFLUX_HOST="bacon.local"
# INFLUX_DB="chipcharge"
# INFLUX_TABLE="chipcharge"

BATTERY_FILE="batterystats2.txt"


# set ADC enabled for all channels
ADC=$(i2cget -y -f 0 0x34 0x82)
# if couldn't perform get, then exit immediately
[ $? -ne 0 ] && exit $?

if [ "$ADC" != "0xff" ] ; then
    i2cset -y -f 0 0x34 0x82 0xff
    # Need to wait at least 1/25s for the ADC to take a reading
    sleep 1
fi

while [ true ] ; do
    BAT_VOLT_MSB=$(i2cget -y -f 0 0x34 0x78)
    BAT_VOLT_LSB=$(i2cget -y -f 0 0x34 0x79)

    BAT_BIN=$(( ($BAT_VOLT_MSB << 4) | ($BAT_VOLT_LSB & 0x0F) ))
    BAT_VOLT=$(echo "$BAT_BIN*1.1"|bc)

    POWER_STATUS=$(i2cget -y -f 0 0x34 0x00)

    if [ $(($POWER_STATUS & 0x04)) -ne 0 ] ; then
      # Charging
      BAT_ICHG_MSB=$(i2cget -y -f 0 0x34 0x7A)
      BAT_ICHG_LSB=$(i2cget -y -f 0 0x34 0x7B)
      BAT_ICHG_BIN=$(( ($BAT_ICHG_MSB << 4) | ($BAT_ICHG_LSB & 0x0F) ))
    else
      # Discharging
      BAT_ICHG_MSB=$(i2cget -y -f 0 0x34 0x7C)
      BAT_ICHG_LSB=$(i2cget -y -f 0 0x34 0x7D)
      BAT_ICHG_BIN=$(( ($BAT_ICHG_MSB << 5) | ($BAT_ICHG_LSB & 0x1F) ))
    fi

    BAT_ICHG=$(echo "$BAT_ICHG_BIN*0.5"|bc)

    X="$BAT_VOLT volts,$BAT_ICHG mA"
    CURRENT_TIME=$(date +"%H:%M:%S")
    BATTERY_CSV="$CURRENT_TIME,$BAT_VOLT,$BAT_ICHG"

    echo $X

#    curl -XPOST --data-binary "$INFLUX_TABLE $X" \
#      http://$INFLUX_HOST:8086/write?db=$INFLUX_DB

    echo $BATTERY_CSV >> $BATTERY_FILE

    sleep 5
done
