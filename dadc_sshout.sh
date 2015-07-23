#!/bin/bash
# Redirect output of dadcmon to ssh
server=andrey@130.199.23.227
echo "The logging is goung to $server:dadc.log"
/home/pi/spi/dadcmon -m | ssh andrey@130.199.23.227 'cat >> dadc.log'


