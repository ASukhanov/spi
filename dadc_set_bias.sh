#!/bin/bash
# Set Bias Voltage on emco_ad5592 board.
ChBPrg=2
if [ -n "$EMCO_AD5592_v5" ]; then ChBPrg=1; fi
CMD="ad5592.sh -d$ChBPrg=$1 -x0"
echo "executing: $CMD"
eval $CMD

