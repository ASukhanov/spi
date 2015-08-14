#!/bin/bash
# Set Bias Voltage on emco_ad5592 board on the server with the EMCO_AD5592 board.
# The DADC_SERVER should be exported prior to running this script i.e.:
# $ export DADC_SERVER=pi@130.199.23.244

CMD="ssh $DADC_SERVER 'ad5592.sh -d1=$1 -x0'"
echo "executing: $CMD"

eval $CMD
#ssh pi@130.199.23.244 "$CMD"

