#!/bin/bash
dadcmon -m >> /home/pi/dadc.log&
python /home/pi/work/spi/stripchart_log.py -m&
