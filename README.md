# spi
Control and monitor for SPI ADC/DACs, fast stripcharts.  

Programs and scripts:

dadcmon:	Server program for AD5592 ADC/DAC chip for EMCO_AD5592 Bias Source and Nanoammeter board.

ad5592.sh       Control script for dadcmon

ad5592-v7.sh:	Channel map of the v7 PCB

stripchart_log.py:	Fast graphical stripchart of a logfile using pyqtgraph

stripchart_example.py:	Stripchart example using random data.

############################################################

To initialize the EMCO_AD5592 board execute:
ad5592.sh -i

 
