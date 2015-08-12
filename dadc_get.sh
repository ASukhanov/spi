#!/bin/bash
# Get ADC readings from the server with EMCO_AD5592 board
# The DADC_SERVER should be exported prior to running this script i.e.:
# $ export DADC_SERVER=pi@130.199.23.244

CMD="ssh $DADC_SERVER 'spi/dadcmon -m' >>/tmp/dadc.log"
echo executing: $CMD

#ssh $DADC_SERVER 'spi/dadcmon -m' >>/tmp/dadc.log
eval $CMD

