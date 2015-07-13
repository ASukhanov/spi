#!/bin/bash
usage ()
{
cat << EOF
usage: usage: $0 options

Control of the AD5592

OPTIONS:
  options
  -v	Verbosity
  -r N  Read N 16-bit words
  -a M  read ADC sequence of channels specified by hex mask M, may follow with -r N
  -t M  same as -a M but includes temperature in the sequence

EXAMPLE:
  $0
EOF
}
#c=''; for i in `seq 0 9`; do c=$c$i; done; echo $c
#'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
OPTIND=1    	# do not skip arguments
while getopts "vr:a:t:h" opt; do
  #echo "opt=$opt"
  case $opt in
	v)  VERB="-v";;
	r)  for i in `seq 1 $OPTARG`; do c=$c'0'; done; echo $c; eval ./spidev_test -p $c $VERB;;
	h)  usage;;
	?)  echo "ERROR, Illegal option"; exit 1;;
	*)  ;;
  esac
done

