#!/bin/sh
#
# For the CHIP Computer AXP09 Power mangement IC
#
# Jeff Brown http://photonicsguy.ca/projects/chip
# https://github.com/Photonicsguy/CHIP
# Version 1.0 (April 5th, 2016)
#
# It looks like you can destroy your chip computer by writing the wrong data to certain registers on this chip!
# (Some of the voltage outputs are programmable via registers)
#
# There is only one write command in this script (to enable ADC registers)
#
#
#
# ACIN is PIN2 of U13 (Labeled CHG-IN)
# VBUS is USB power
# VBAT is Battery (Of course)
#
#
# Lower 2 bits of Register 30 control the VBUS current limiting
#i2cset -y -f 0 0x34 0x30 0x60	# 900mA VBUS current limit (Default)
#i2cset -y -f 0 0x34 0x30 0x61	# 500mA VBUS current limit
#i2cset -y -f 0 0x34 0x30 0x62	# 100mA VBUS current limit (CHIP will draw from both VBUS & Battery)
#i2cset -y -f 0 0x34 0x30 0x63	# No current limiting on VBUS
#
#
#

if [ "$1" == "-a" ]; then
	ALL=true
elif [ "$1" == "-v" ]; then
	echo "Version 1.0 (April 5th, 2016)"
	echo "https://github.com/Photonicsguy/CHIP"
	exit 0
elif [ "$1" == "-b" ]; then
	BP=true
#elif [ "$1" == "-q" ]; then
elif [ "$1" == "-h" ]; then
	cat << EOF
Usage: axp209.sh [OPTION]
	-a	Display all data
	-v	Version
	-h	Help (This help)
	-b	Show only battery percentage

exits 0 on ACIN/VBUS power
exits 1 on Battery power (If battery is discharging)

EOF
fi

# Enable ADC registers
i2cset -y -f 0 0x34 0x82 0xff

##	REGISTER 00	##
REG=$(i2cget -y -f 0 0x34 0x00)
STATUS_ACIN=$(($(($REG&0x80))/128))
STATUS_ACIN_AVAIL=$(($(($REG&0x40))/64))
STATUS_VBUS=$(($(($REG&0x20))/32))
STATUS_VBUS_AVAIL=$(($(($REG&0x10))/16))
STATUS_VHOLD=$(($(($REG&0x08))/8))
STATUS_CHG_DIR=$(($(($REG&0x04))/4))
ACVB_SHORT=$(($(($REG&0x02))/2))
STATUS_BOOT=$(($REG&0x01))


if [ $ALL ];then
	REG=$(i2cget -y -f 0 0x34 0x30)
	VHOLD="4."$(($(($REG&0x38))/8))
	REG=$(($REG&0x3))
	case "$REG" in
		0)
			VBUS_C_LIM="900mA"
			;;
		1)
			VBUS_C_LIM="500mA"
			;;
		2)
			VBUS_C_LIM="100mA"
			;;
		3)
			VBUS_C_LIM="No limit"
			;;
	esac
	
	VSHUTDOWN="2."$(($(($(i2cget -y -f 0 0x34 0x31)&0x07))+6))
	REG=
	echo "              ACIN: $STATUS_ACIN	Avail: $STATUS_ACIN_AVAIL"
	echo "              VBUS: $STATUS_VBUS	Avail: $STATUS_VBUS_AVAIL"
	echo "             VHOLD: $STATUS_VHOLD (Whether VBUS is above $VHOLD""V before being used)"
	#echo "  Charge direction: $STATUS_CHG_DIR	(0:Battery discharging; 1:The battery is charging)"
	echo "  Shutdown voltage: $VSHUTDOWN"V""
	echo "VBUS current limit: $VBUS_C_LIM"

fi
if [ $ACVB_SHORT == 1 ]; then
	echo "ACIN & VBUS input short circuit on PCB"
fi

if [ $ALL ]; then
	echo -n "Boot source is"
	if [ $STATUS_BOOT == 0 ]; then
		echo -n "n't"
	fi
	echo " ACIN/VBUS"
fi


##	REGISTER 01	##
REG=$(i2cget -y -f 0 0x34 0x01)
STATUS_OVRTEMP=$(($(($REG&0x80))/128))
STATUS_CHARGING=$(($(($REG&0x40))/64))
STATUS_BATCON=$(($(($REG&0x20))/32))
#STATUS_=$(($(($REG&0x10))/16))
STATUS_ACT=$(($(($REG&0x08))/8))
STATUS_CUREXPEC=$(($(($REG&0x04))/4))
#STATUS_=$(($(($REG&0x02))/2))
#STATUS_=$(($REG&0x01))

if [ $STATUS_OVRTEMP == 1 ]; then
	echo "Over Temperature"
fi
if [ $ALL ]; then
	if [ $STATUS_CHARGING == 1 ]; then
		echo "Battery charging"
	fi
	echo "Battery connected: $STATUS_BATCON"
fi

if [ $STATUS_ACIN==1 ]; then
	# ACIN voltage
	REG=`i2cget -y -f 0 0x34 0x56 w|awk '{print "0x"substr($0,5,2)substr($0,4,1)}'`
	REG=`printf "%d" "$REG"`
	ACIN=`echo "$REG*0.0017"|bc`
	# ACIN Current
	REG=`i2cget -y -f 0 0x34 0x58 w|awk '{print "0x"substr($0,5,2)substr($0,4,1)}'`
	REG=`printf "%d" "$REG"`
	ACIN_C=`echo "$REG*0.375"|bc`
else
	ACIN='-'
	ACIN_C='-'
fi

if [ $STATUS_VBUS==1 ]; then
	# VBUS voltage
	REG=`i2cget -y -f 0 0x34 0x5A w|awk '{print "0x"substr($0,5,2)substr($0,4,1)}'`
	REG=`printf "%d" "$REG"`
	VBUS=`echo "$REG*0.0017"|bc`

	# VBUS Current
	REG=`i2cget -y -f 0 0x34 0x5C w|awk '{print "0x"substr($0,5,2)substr($0,4,1)}'`
	REG=`printf "%d" "$REG"`
	VBUS_C=`echo "$REG*0.375"|bc`
else
	VBUS='-'
	VBUS_C='-'
fi

if [ $STATUS_BATCON==1 ]; then
	# Battery Voltage
	REG=`i2cget -y -f 0 0x34 0x78 w|awk '{print "0x"substr($0,5,2)substr($0,4,1)}'`
	REG=`printf "%d" "$REG"`
	VBAT=`echo "$REG*0.0011"|bc`

	if [ $STATUS_CHG_DIR == 1 ]; then
		# Battery Charging Current
		REG=`i2cget -y -f 0 0x34 0x7A w|awk '{print "0x"substr($0,5,2)substr($0,4,1)}'`
		REG_C=`printf "%d" "$REG"`
		BAT_C=`echo "scale=2;$REG_C*0.5"|bc`
	else
		# Battery Discharge Current
		REG=`i2cget -y -f 0 0x34 0x7C w|awk '{print "0x"substr($0,5,2)substr($0,4,1)}'`
		REG_D=`printf "%d" "$REG"`
		BAT_D=`echo "scale=2;$REG_D*0.5"|bc`
	fi
	# Battery %
	REG=`i2cget -y -f 0 0x34 0xB9`
	BAT_PERCENT=`printf "%d" "$REG"`
else
	VBAT='-'
	BATT_CUR='-'
	BAT_PERCENT='-'
	echo "No Battery connected"
fi
# System (IPSOUT) Voltage (IPS is Intelligent Power Select)
REG=`i2cget -y -f 0 0x34 0x7E w|awk '{print "0x"substr($0,5,2)substr($0,4,1)}'`
REG=`printf "%d" "$REG"`
IPSOUT=`echo "$REG*0.0014"|bc`


if [ $ALL ]; then
	# Temperature
	REG=`i2cget -y -f 0 0x34 0x5E w|awk '{print "0x"substr($0,5,2)substr($0,4,1)}'`
	REG=`printf "%d" "$REG"`
	THERM=`echo "($REG*0.1)-144.7"|bc`
	echo "Temperature:	"$THERM"°C (I've seen as high as 65°C)"
fi
echo "Battery: $BAT_PERCENT""%"
if [ $BP ];then						# If -b switch is used, exit after showing battery percentage
	if [ $STATUS_CHG_DIR == 0 ]; then
		exit 1	# CHIP operating on Battery
	else
		exit 0	# CHIP on ACIN/VBUS power
	fi
fi

echo -n "ACIN:	$ACIN""V"
if [ $ACIN_C != 0 ];then 
	echo "   "$ACIN_C"mA"
else
	echo ""
fi

echo -n "VBUS:	$VBUS""V"
if [ $VBUS_C != 0 ];then
	echo "   "$VBUS_C"mA"
else
	echo ""
fi

echo -n "VBAT:	$VBAT V  "
if [ $STATUS_CHG_DIR == 1 ]; then
	echo "Charging at "$BAT_C"mA"
else
	echo "Discharging at "$BAT_D"mA"
fi
echo "Vout:	$IPSOUT V"

if [ $STATUS_CHG_DIR == 0 ]; then
	exit 1	# CHIP operating on Battery
else
	exit 0	# CHIP on ACIN/VBUS power
fi


