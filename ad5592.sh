#!/bin/bash
usage ()
{
cat << EOF
usage: usage: $0 options

Control of the AD5592 ADC/DAC

OPTIONS:
  options
  -v    Verbosity
  -i    Init
  -a M  Schedule the reading of ADC sequence of channels specified by hex mask M, may follow with $
  -t M  Same as -a M but includes temperature in the sequence
  -r R  Select register for future write operation
  -w W  Schedule the writing of 11 bits W[10:0] into the selected register
  -x N  Execute the scheduled transfers, followed by reading of N 16-bit words
  -b R  Read back the setting of register R
  -z    reset

EXAMPLE:
  write 0x1234 into reg[3] and read back its content
  $0 -v -r3 -w16#1234 -x1 -b3
  read ADC[4] and  ADC[0]:
  $0 -v -a16#11 -r3     # first 4 bytes should be ignored
EOF
}
#,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
#'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
#SPIDEV_CMD="./ad5592 -d0 -l"
SPIDEV_CMD="./ad5592 "
VERB=""
                                 #5432109876543210
((Reg_General_Purpose_Control = 2#0001100000110000)) #
((Reg_ADC_Config              = 2#0010100011110000)) #
((Reg_DAC_Config              = 2#0001100000001111)) #
((Reg_Readback                = 2#0011100001000000)) #
((Reg_Reset                   = 2#0111110110101100)) #
((Reg_Sequencer_REP=16#200))    #repeat
((Reg_Sequencer_TEMP=0))        #temperature, if needed set to 16#100
twoz="\x00\x00"
#,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
#'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
function get_two_bytes {
  HEX=`printf '%04x' $1`
  #if [ -n "$VERB" ]; then echo "hex=$HEX"; fi;
  two_bytes=\\x${HEX:0:2}\\x${HEX:2:2}
}
BYTES=""
function read_adc {
  ((Reg_Sequencer=(16#2)<<11 | $1 | $Reg_Sequencer_REP | $Reg_Sequencer_TEMP))
  printf '%04x\n' $Reg_Sequencer
  if [ -n "$VERB" ]; then printf 'Reg_Sequence = %04x\n' $Reg_Sequencer; fi
  HEX=`printf '%04x' $Reg_Sequencer`
  BYTES=$BYTES\\x${HEX:0:2}\\x${HEX:2:2}
}
function transfer {
  CMD="$SPIDEV_CMD $VERB -p\"$1\"";
  if [ -n "$VERB" ]; then echo "executing: $CMD"; fi
  eval $CMD;
}
#'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
OPTIND=1    	# do not skip arguments
while getopts "vx:a:t:ib:r:w:zh" opt; do
  if [ -n "$VERB" ]; then echo "opt,optarg=$opt,$OPTARG"; fi
  case $opt in
    v) VERB="-v";;
    x)
       for i in `seq 1 $OPTARG`; do BYTES=${BYTES}$twoz; done
       transfer $BYTES;
       BYTES="";
       ;;
    a) read_adc $OPTARG;;
    t) ((Reg_Sequencer_TEMP=16#100)); read_adc $OPTARG;;
    i)
       get_two_bytes $Reg_ADC_Config;
       list=$two_bytes;
       get_two_bytes $Reg_DAC_Config;
       list=$list$two_bytes
       get_two_bytes $Reg_General_Purpose_Control;
       list=$list$two_bytes
       transfer $list;
       ;;
    b)
       ((v = $Reg_Readback | (($OPTARG & 0xF) << 2) ))
       #if [ -n "$VERB" ]; then printf "v=%04x\n" $v; fi
       get_two_bytes $v;
       transfer $two_bytes$twoz;
       ;;
    r) ((Reg = (($OPTARG & 0xF) << 11) ));;
    w)
       ((Reg = $Reg | ($OPTARG & 0x7FFF) ));
       get_two_bytes $Reg;
       BYTES=$BYTES$two_bytes;
       ;;
    z)
       get_two_bytes $Reg_Reset
       transfer $two_bytes;
       ;;
    h) usage;;
    :) echo "ERROR, Option argument is required"; exit 1;;
    ?) echo "ERROR, Illegal option"; exit 1;;
    *)  ;;
  esac
done
