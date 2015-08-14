#!/bin/bash
# Reset and init the EMCO_AD5592 board on the server. Bias will be turned to minimum (3V).
# The DADC_SERVER should be exported prior to running this script i.e.:
# $ export DADC_SERVER=pi@130.199.23.244

CMD="ssh $DADC_SERVER 'ad5592.sh -z -i -b11'" # one can add -b11 for readback
echo "executing: $CMD"

eval $CMD
#ssh pi@130.199.23.244 "$CMD"

