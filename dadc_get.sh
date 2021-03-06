#!/bin/bash
# Get readings of 8 ADC channels and temperature from the server with the EMCO_AD5592 board.
# The DADC_SERVER should be exported prior to running this script i.e.:
# $ export DADC_SERVER=pi@130.199.23.244

CMD="ssh $DADC_SERVER 'dadcmon -m' >>/tmp/dadc.log"
echo executing: $CMD

eval $CMD

