# CHIP

Shell script for reading voltage & current from the AXP209 Power Management IC for the CHIP $9 computer
  * Battery charge %
  * Battery voltage & current
  * USB voltage & current
  * "ACIN" (Pin 2 of U13) voltage & current
  * and more...

<STRONG>Example</STRONG>
<PRE>
root@chip:~# axp209.sh 
Battery: 92%
ACIN:	0V
VBUS:	4.8892V   899.625mA
VBAT:	4.2075 V  Charging at 633.0mA
Vout:	4.3876 V
</PRE>
<STRONG>with -a switch</STRONG>
<PRE>
root@chip:~# axp209.sh  -a
              ACIN: 0	Avail: 0
              VBUS: 1	Avail: 1
             VHOLD: 1 (Whether VBUS is above 4.4V before being used)
  Shutdown voltage: 2.9V
VBUS current limit: 900mA
Boot source isn't ACIN/VBUS
Battery charging
Battery connected: 1
Temperature:	56.8°C (I've seen as high as 65°C)
Battery: 92%
ACIN:	0V
VBUS:	4.8858V   899.625mA
VBAT:	4.2119 V  Charging at 633.0mA
Vout:	4.5962 V
</PRE>
<STRONG>100mA USB current limit</STRONG> (Causing the AXP209 to power the CHIP from both USB and the battery)
<PRE>
root@chip:~# axp209.sh -a
              ACIN: 0	Avail: 0
              VBUS: 1	Avail: 1
             VHOLD: 1 (Whether VBUS is above 4.4V before being used)
  Shutdown voltage: 2.9V
VBUS current limit: 100mA
Boot source isn't ACIN/VBUS
Battery charging
Battery connected: 1
Temperature:	45.0°C (I've seen as high as 65°C)
Battery: 99%
ACIN:	0V
VBUS:	5.1442V   100.500mA
VBAT:	4.1371 V  Discharging at 68.5mA
Vout:	4.1006 V
</PRE>
<HR WIDTH="70%">

<H2>WARNING:</H2>
Some of the voltage outputs are programmable via registers, so it appears to be possible to damage your CHIP computer by writing the wrong data to certain registers on this chip.
<BR>This script only uses one write command to enable ADC registers, everything else is only reading registers.


<h3>References:</H3>
  * http://docs.getchip.com/ - CHIP Documentation
  * http://linux-sunxi.org/AXP209 - Information on chip registers
