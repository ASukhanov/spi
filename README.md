# spi
Support for some SPI devices on raspberry pi

Programs and scripts:

ad5592.sh	Control script of 

dadcmon:	Server program for AD5592 ADC/DAC chip for EMCO_AD5592 Bias Source and Nanoammeter board.

ad5592-v7.sh:	Channel map of the v7 PCB

stripchart_log.py:	Graphical stripchart of a logfile using pyqtgraph

############################################################

To initialize the EMCO_AD5592 board execute:
ad5592.sh -i

To run it on startup, add the following line to /etc/rc.local:
bash /usr/local/bin/ad5592.sh -i

 
