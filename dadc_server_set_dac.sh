#!/bin/bash
# Set DAC on emco_ad5592 board on server
CMD="/home/pi/spi/ad5592.sh -d$1=$2 -x0"
echo "executing on server: $CMD"
ssh pi@130.199.23.244 "$CMD"

