# spi
Support for some SPI devices on raspberry pi

Programs and scripts:
ad5592.sh	Control script
dadcmon:	Server program
ad5592-v7.sh:	Channel map of the v7 PCB

To initialize the EMCO_AD5592 board execute:
ad5592.sh -i

To run it on startup, add the following line to /etc/rc.local:
bash /usr/local/bin/ad5592.sh -i

 
