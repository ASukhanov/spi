#!/bin/bash
usage()
{
cat << EOF
usage: $0 Voltage
Set Bias Voltage on EMCO_AD5552 board.
Voltage should be in range {3V..400V}
EOF
}
if [ "$#" -lt "1" ]; then usage; exit; fi;

ChBPrg=2
if [ -n "$EMCO_AD5592_v5" ]; then ChBPrg=1; fi
dac_setting=$(( 40 + ($1 - 6)*1000/3/100 )) # convert volts to dac values
CMD="ad5592.sh -d$ChBPrg=$dac_setting -x0"
echo "executing: $CMD"
eval $CMD

