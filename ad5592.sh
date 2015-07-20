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
  -wRR=W  Schedule the writing of 11 bits W[10:0] into the register R.
        R should be 2-digit field. 01:07 setup registers, 08:15 DAC registers
  -xN   Execute the scheduled transfers, followed by the reading of N 16-bit
        words.
  -bR   Read back the setting of register R.
  -dR=W  Set DAC[R]=W. R should be less than 8.
  -DR   Read DAC[R], use -x1 to get the reading
  -z    reset.

EXAMPLES:
  reset and read Reg[6]
  $0 -z -b6
  the result should be:
RX | 00 00 __ __ __ __ __ __ __ __ __ __ __ __ __ __  | ..
RX | 00 00 00 7F __ __ __ __ __ __ __ __ __ __ __ __  | ..

  Configure 8 channels as ADCs (e.g. write 0xFF into reg[4])
  Configure channels 1,3,5,7 as DACs (e.g. write 0xAA into reg[5])
  $0 -w040xAA -w050xFF -x0

  Monitor 7 ADC channels and temperature every second:
  $0 -a0x37f -x0  # set ADC repetitive mode and enable 7 ADCs in sequence
  while true ; do ./ad5592.sh -x8; sleep 1; done

  Turn off ADC repetitive mode.
  $0 -a0 -x0

  write 0x330 into the General Purpose Register and read back
  $0 -w03=16#330 -x0 -b3
  the result should be: RX | 00 00 00 F0

  set DAC[1] to 0x200 and read it back
  $0 -s1=0x200 -w010x19 -x1

  read back all registers:
  $0 -b1 -b2 -b3 -b4 -b5 -b6 -b7 -b8 -b9 -b10 -b11 -b12 -b13

  report temperature of the chip:
  while true; do $0 -a0x100 -x0; sleep 1; done;
EOF
}
#,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
#'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
# Default setting of the ad5592
#
# Default spidev command
#SPIDEV_CMD="./ad5592 -H"	#obsolete#ad5592 reacts on falling edge of the clock
SPIDEV_CMD="./dadcmon -H"       #ad5592 reacts on falling edge of the clock
VERB=""

# Default register setting
                                 #5432109876543210
((Reg_Powerdown               = 2#0101101000000000)) 
# Enable internal reference
((Reg_General_Purpose_Control = 2#0001101100110000)) #
# addr=3, ADC buffer enabled, Lock off, not AllDACs, ADC range 2x, DAC: 2x.
((Reg_ADC_Config              = 2#0010000111111111)) # all ADCs and temperature selected
((Reg_Sequencer               = 2#0001000000000000)) # empty sequencer
((Reg_DAC_Config              = 2#0010100010101010)) # setting for the EMCO board
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
while getopts "vx:a:ib:w:d:D:zh" opt; do
  if [ -n "$VERB" ]; then echo "opt,optarg=$opt,$OPTARG"; fi
  case $opt in
    v) VERB="-v";;
    x)
       for i in `seq 1 $OPTARG`; do BYTES=${BYTES}$twoz; done
       transfer $BYTES;
       BYTES="";
       ;;
    a)
       ((Reg_Sequencer = Reg_Sequencer | ($OPTARG & 0x7FF) ))
       #printf '%04x\n' $Reg_Sequencer
       if [ -n "$VERB" ]; then printf 'Reg_Sequence = %04x\n' $Reg_Sequencer; fi
       HEX=`printf '%04x' $Reg_Sequencer`
       BYTES=$BYTES\\x${HEX:0:2}\\x${HEX:2:2}
       ;;
    i)
       get_two_bytes $Reg_Powerdown;
       list=$two_bytes;
       get_two_bytes $Reg_Sequencer;
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
       ((Reg = ${OPTARG:0:2}<<11 | (${OPTARG:3} & 0x7FF) ));
       get_two_bytes $Reg;
       BYTES=$BYTES$two_bytes;
       ;;
    d)
       ((Reg = 0x8000 | ${OPTARG:0:1}<<12 | (${OPTARG:2} & 0xFFF) ));
       get_two_bytes $Reg;
       BYTES=$BYTES$two_bytes;
       ;;
    D)
       ((Reg = 0x0818 | (${OPTARG:0:1} & 0xF) ));
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
