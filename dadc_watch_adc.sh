#!/bin/bash
# This is obsolete, 'dadcmon -m'  will do the job 
# Watch 7 adc channels and temperature
#./ad5592.sh -a0x17f -x0
./ad5592.sh -a0x37f -x0
while true ; do ./ad5592.sh -x8; sleep 1; done

