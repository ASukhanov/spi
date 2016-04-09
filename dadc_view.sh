#!/bin/bash
# Display the EMCO_AD5592 ADCs

if [ -n "$EMCO_AD5592_v5" ];
then
  TITLE="EMCO_AD5592_v5 Monitor"
  FIELDS="date------ time---- BMon BPrg IBHR ad3  ad4  DVDD ad6  AVDD temp"
else
  TITLE="EMCO_AD5592_v7 Monitor"
  FIELDS="date------ time---- BMon IBHR BPrg IBLR ad4  ad5  AVDD DVDD temp"
fi

echo "$TITLE"
echo "$FIELDS"

#start monitoring with changed trip level
dadcmon -t1100 -m
