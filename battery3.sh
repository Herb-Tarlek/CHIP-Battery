#!/bin/sh

###########################################################
#
#       :   ``   :
#       ;   ;;   ;
#       ;   ;;   ;
#    ;;;;;;;;;;;;;;;;     Battery Stats for the C.H.I.P.
#    ;.````````````.;     ***Original by CapnBry***
#    ;`            `;
# :;;;`            `;;;:  ***v.2 by Herb_Tarlek***
#    ;`  ;;;       `;
#    ;`  ;;;.      `;
#    ;`  ;;;,      `;     Special thanks to zerotri on IRC
# `;;;`   .`;;;;;;;;;;;`  Come join us on IRC! #chipsters on
# `;;;`       `,:;;;;;;`  Freenode.
#    ;`            `;
#    ;`            `;
#    ;`            `;
# :;;;`            `;;;:
#    ;`            `;
#    ;.````````````.;
#    ;;;;;;;;;;;;;;;;
#       ;   ;;   ;
#       ;   ;;   ;
#       :   ``   :
#
###########################################################

STATS_FILE="batterystats.$(date +"%R").txt"
MYSELF=$(whoami)
BOLD_TEXT=$(tput bold)
NORMAL_TEXT=$(tput sgr0)


# Check for i2c group
#

if [ $(id -Gn "$MYSELF" | grep -c "i2c") -eq "0" ]; then
	echo "I'm sorry, $MYSELF, you're not in the ${BOLD_TEXT}i2c${NORMAL_TEXT} group."
	echo "Please execute '${BOLD_TEXT}sudo usermod -a -G i2c $MYSELF${NORMAL_TEXT}', logout and login (or reboot),"\
	"and try again."
	exit
fi
#
#
#

echo "This script will test your battery in both charging and discharging mode."
echo "The data will be collected in a CSV (Comma Seperated Value) file named ${BOLD_TEXT}$STATS_FILE${NORMAL_TEXT}."
echo "If this filename is OK, press enter; otherwise, give a new filename and press enter."
echo -n "New filename [Enter for default]:"
read NEW_FILENAME
if [ -n "$NEW_FILENAME" ]; then
	STATS_FILE=$NEW_FILENAME
fi

#Write column headers to data file
echo "Time, mV, mA" >> $STATS_FILE


#Prettier output header
printf "==================================\n"
printf "Press Ctrl-C to end the script.\n"

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

#write the data to the CSV file
    echo $BATTERY_CSV >> $STATS_FILE

#Make the output refresh on the same line.
# \r is carriage return
# \e[K is the escape code to clear the line
    printf "\r\e[K%smV, %smA" $BAT_VOLT $BAT_ICHG

# wait 5 seconds
    sleep 5
done
