#!/bin/bash
usage ()
{
cat << EOF
usage: usage: $0 options

Control of the AD5592 ADC/DAC

OPTIONS:
  options
  -v    Verbosity
  -i    Init, default setting of the ad5592, should be executed after
        power up.
  -aM   Schedule the reading of ADC channels specified by the mask M.
        bits M[7:0] specify the ADC channels for readout
        bit M[8]: include temperature in the readout sequence
        bit M[9]: repeat mode of the ADC readout
  -wRW  Schedule the writing of 11 bits W[10:0] into the register RR.
        R should be 2-digit field ranging from 01 to 14.
  -x N  Execute the scheduled transfers, followed by the reading of N 16-bit
        words.
  -b R  Read back the setting of register R.
  -z    reset.

EXAMPLES:
  reset and read Reg[6]
  $0 -z -b6
  the result should be:
RX | 00 00 __ __ __ __ __ __ __ __ __ __ __ __ __ __  | ..
RX | 00 00 00 7F __ __ __ __ __ __ __ __ __ __ __ __  | ..

  configure 8 channels as DACss (e.g. write 0xFF into reg[5])
  $0 -w050xFF -x0

  configure 8 channels as ADCs (e.g. write 0xFF into reg[4])
  $0 -w040xFF -x0

  read temperature and 8 ADC channels:
  $0 -a0x1ff -x9
  or: $0 -a16#1ff -x9
  or: $0 -a2#111111111 -x9

  write to General Purpose Register 0x00F0 and read back
  $0 -v -r3 -w16#f0 -x1 -b3
  the result should be: RX | 00 00 00 F0

  read back all registers:
  $0 -b1 -b2 -b3 -b4 -b5 -b6 -b7 -b8 -b9 -b10 -b11 -b12 -b13

  write 0x1234 into reg[3] and read back its content
  $0 -v -r3 -w16#1234 -x1 -b3

  read ADC[4] and  ADC[0]:
  $0 -v -a16#11 -r3     # first 4 bytes should be ignored

  report temperature of the chip:
  while true; do $0 -a0x100 -x0; sleep 1; done;
EOF
}
#,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
#'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
# Default setting of the ad5592
#
# Default spidev command
SPIDEV_CMD="./ad5592 -H"	#ad5592 reacts on falling edge of the clock
VERB=""

# Default register setting
                                 #5432109876543210
((Reg_Powerdown               = 2#0101101000000000)) 
# Enable internal reference
((Reg_General_Purpose_Control = 2#0001101100110000)) #
# addr=3, ADC buffer enabled, Lock off, not AllDACs, ADC range 2x, DAC: 2x.
((Reg_ADC_Config              = 2#0010000111110000)) #
((Reg_DAC_Config              = 2#0010100000001111)) #
((Reg_Readback                = 2#0011100001000000)) #
((Reg_Reset                   = 2#0111110110101100)) #
twoz="\x00\x00"
#,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
#'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
function get_two_bytes {
  HEX=`printf '%04x' $1`
  #if [ -n "$VERB" ]; then echo "hex=$HEX"; fi;
  two_bytes=\\x${HEX:0:2}\\x${HEX:2:2}
}
BYTES=""
ADC_REPEAT=0
ADC_TEMPERATURE=0

function transfer {
  CMD="$SPIDEV_CMD $VERB -p\"$1\"";
  if [ -n "$VERB" ]; then echo "executing: $CMD"; fi
  eval $CMD;
}
#'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
OPTIND=1    	# do not skip arguments
while getopts "vx:a:ib:w:zh" opt; do
  if [ -n "$VERB" ]; then echo "opt,optarg=$opt,$OPTARG"; fi
  case $opt in
    v) VERB="-v";;
    x)
       for i in `seq 1 $OPTARG`; do BYTES=${BYTES}$twoz; done
       transfer $BYTES;
       BYTES="";
       ;;
    a)
       ((Reg_Sequencer = 2<<11 | ($OPTARG & 0x7FF) ))
       #printf '%04x\n' $Reg_Sequencer
       if [ -n "$VERB" ]; then printf 'Reg_Sequence = %04x\n' $Reg_Sequencer; fi
       HEX=`printf '%04x' $Reg_Sequencer`
       BYTES=$BYTES\\x${HEX:0:2}\\x${HEX:2:2}
       ;;
    i)
       get_two_bytes $Reg_PowerDown;
       list=$two_bytes;
       get_two_bytes $Reg_ADC_Config;
       list=$list$two_bytes;
       get_two_bytes $Reg_DAC_Config;
       list=$list$two_bytes;
       get_two_bytes $Reg_General_Purpose_Control;
       list=$list$two_bytes;
       transfer $list;
       ;;
    b)
       ((v = $Reg_Readback | (($OPTARG & 0xF) << 2) ))
       get_two_bytes $v;
       transfer $two_bytes$twoz;
       ;;
    w)
       ((Reg = ${OPTARG:0:2}<<11 | (${OPTARG:2} & 0x7FF) ));
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
