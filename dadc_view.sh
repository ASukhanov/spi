-
#!/bin/bash
# Display the EMCO_AD5592 ADCs
# To work with old EMCO_AD5592_v5 board the $EMCO_AD5592-v5 environment variable should be exported
source /usr/local/lib/simple_curses.sh

PCB="EMCO_AD5592_v7"
if [ -n "$EMCO_AD5592_v5" ]; then PCB="EMCO_AD5592_v5"; fi
COUNT=1

#create main function
main(){
   window "[$COUNT] $PCB PS and Bias Control [$EMCO_AD5592_v5]"
   ((COUNT=COUNT+1))
   if [ -n "$EMCO_AD5592_v5" ];
     then #v5 PCB
       append_tabbed "date------ time---- BMon BPrg IBHR ad3  ad4  DVDD ad6  AVDD temp" 11 " "
     else #v7 PCB
       append_tabbed "date------ time---- BMon IBHR BPrg IBLR ad4  ad5  AVDD DVDD temp" 11 " "
   fi
   append_tabbed "`dadcmon -M1`" 11 " "
   endwin
}
#then ask the standard loop
main_loop

