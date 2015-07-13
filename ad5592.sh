#!/bin/bash
usage ()
{
cat << EOF
usage: usage: $0 options

Control of the AD5592 ADC/DAC

OPTIONS:
  options
  -v	Verbosity
  -r N  Read N 16-bit words
  -a M  read ADC sequence of channels specified by hex mask M, may follow with -r N
  -t M  same as -a M but includes temperature in the sequence
  -x    execute

EXAMPLE:
  read ADC[4] and  ADC[0]:
  ./ad5592.sh -v -a16#11 -r3	# first 4 bytes should be ignored
EOF
}
((Reg_Sequencer_REP=16#200))	#repeat
((Reg_Sequencer_TEMP=0))	#temperature, if needed set to 16#100
BYTES=""
function read_adc {
  ((Reg_Sequencer=(16#2)<<11 | $1 | $Reg_Sequencer_REP | $Reg_Sequencer_TEMP))
  printf '%04x\n' $Reg_Sequencer
  printf 'Reg_Sequence = %04x\n' $Reg_Sequencer
  HEX=`printf '%04x\n' $Reg_Sequencer`
  BYTES=$BYTES\\x${HEX:2:2}\\x${HEX:0:2}
}
#'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
OPTIND=1    	# do not skip arguments
while getopts "vr:a:t:hx" opt; do
  #echo "opt=$opt"
  case $opt in
    v) VERB="-v";;
    r) for i in `seq 1 $OPTARG`; do BYTES=$BYTES'0'; done;;
    a) read_adc $OPTARG;;
    t) ((Reg_Sequencer_TEMP=16#100)); read_adc $OPTARG;;
    x) CMD="./spidev_test $VERB -p\"$BYTES\""; echo $CMD; eval $CMD;;
    h) usage;;
    ?) echo "ERROR, Illegal option"; exit 1;;
    *)  ;;
  esac
done

