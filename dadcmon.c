/*
 * SPI testing utility (using spidev driver)
 *
 * Copyright (c) 2007  MontaVista Software, Inc.
 * Copyright (c) 2007  Anton Vorontsov <avorontsov@ru.mvista.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License.
 *
 * Cross-compile with cross-gcc -I/path/to/cross-kernel/include
 */
// Version 20150712	commented out the code, not compatible with raspberry pi
// Version 20150721	monitoring added

#include <stdint.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <getopt.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <linux/types.h>
#include <linux/spi/spidev.h>
#include <unistd.h> //for sleep()
#include <time.h> 

#define ARRAY_SIZE(a) (sizeof(a) / sizeof((a)[0]))

static void pabort(const char *s)
{
	perror(s);
	abort();
}

static const char *device = "/dev/spidev0.0";
static uint32_t mode;
static uint8_t bits = 8;
static uint32_t speed = 500000;
static uint16_t delay;
static int verbose;
static int fd = 0;
static int monitoring = 0;
static int guard_adc_channel = 1;
static int guard_dac_channel = 1;
static int guard_trip_level = 0x800;
#define NCH 9
static int channels[NCH];
static int trip_value = 0;	// value to download into the DAC in case of trip

uint8_t default_tx[] = {
	0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
	0x40, 0x00, 0x00, 0x00, 0x00, 0x95,
	0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
	0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
	0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
	0xF0, 0x0D,
};

uint8_t default_rx[ARRAY_SIZE(default_tx)] = {0, };
char *input_tx;

static void hex_dump(const void *src, size_t length, size_t line_size, char *prefix)
{
	int i = 0;
	const unsigned char *address = src;
	const unsigned char *line = address;
	unsigned char c;

	printf("%s | ", prefix);
	while (length-- > 0) {
		printf("%02X ", *address++);
		if (!(++i % line_size) || (length == 0 && i % line_size)) {
			if (length == 0) {
				while (i++ % line_size)
					printf("__ ");
			}
			printf(" | ");  /* right close */
			while (line < address) {
				c = *line++;
				printf("%c", (c < 33 || c == 255) ? 0x2E : c);
			}
			printf("\n");
			if (length > 0)
				printf("%s | ", prefix);
		}
	}
}

/*
 *  Unescape - process hexadecimal escape character
 *      converts shell input "\x23" -> 0x23
 */
static int unescape(char *_dst, char *_src, size_t len)
{
	int ret = 0;
	char *src = _src;
	char *dst = _dst;
	unsigned int ch;

	while (*src) {
		if (*src == '\\' && *(src+1) == 'x') {
			sscanf(src + 2, "%2x", &ch);
			src += 4;
			*dst++ = (unsigned char)ch;
		} else {
			*dst++ = *src++;
		}
		ret++;
	}
	return ret;
}

static void transfer(uint8_t const *tx, uint8_t const *rx, size_t len)
{
	int ret;
	int ii;

	struct spi_ioc_transfer tr = {
		.tx_buf = (unsigned long)tx,
		.rx_buf = (unsigned long)rx,
		.len = len,
		.delay_usecs = delay,
		.speed_hz = speed,
		.bits_per_word = bits,
	};

/*&RA/	if (mode & SPI_TX_QUAD)
		tr.tx_nbits = 4;
	else if (mode & SPI_TX_DUAL)
		tr.tx_nbits = 2;
	if (mode & SPI_RX_QUAD)
		tr.rx_nbits = 4;
	else if (mode & SPI_RX_DUAL)
		tr.rx_nbits = 2;
*/
	if (!(mode & SPI_LOOP)) {
/*&RA/		if (mode & (SPI_TX_QUAD | SPI_TX_DUAL))
			tr.rx_buf = 0;
		else if (mode & (SPI_RX_QUAD | SPI_RX_DUAL))
			tr.tx_buf = 0;
*/
	}
	ret = ioctl(fd, SPI_IOC_MESSAGE(1), &tr);
	if (ret < 1)
		pabort("can't send spi message");
}
static void decode_rx(uint8_t *rx, int nn, int *channels)
{
	int ii,ch;
	uint16_t w;
	struct tm *now;
	time_t curtime;

	for (ii=0; ii<NCH; ii++) channels[ii] = -1;
	for (ii=0; ii<nn*2;)
	{
		//printf("%02x%02x, ",rx[0],rx[1]);
		ch = ((*rx)>>4)&0xf;
		w = ((*rx++)&0xf)<<8;
		w |= (*rx++);
		ii += 2;
		if(ch>=NCH) continue;
		if(channels[ch] != -1) continue;
		channels[ch] = w;
	}
	curtime = time (NULL);
	now = localtime(&curtime);
	//printf("\n");
	printf("%04i-%02i-%02i %02i:%02i:%02i",
	now->tm_year+1900,now->tm_mon+1,now->tm_mday,now->tm_hour,now->tm_min,now->tm_sec);
	for (ii=0; ii<NCH; ii++) printf(" %04i",channels[ii]);
	printf("\n");
	fflush(stdout);
}
static void guard(int adc_channel, int trip_level, int dac_channel)
{
	uint8_t dacb[] = {0, 0};
	uint8_t ir[2],bb;
	uint16_t *dacw = (uint16_t*) dacb;
	if (channels[adc_channel] > trip_level)
	{
                printf("Trip! ADC[%1i]=%04x exceeds %04x, DAC[%1i] is set to %04x\n",
		adc_channel,channels[adc_channel],trip_level,dac_channel,trip_value);
		*dacw = 0x8000 | (dac_channel&0x7)<<12 | (trip_value&0xfff);
		bb=dacb[0]; dacb[0]=dacb[1]; dacb[1]=bb; //swap bytes
	}
	transfer(dacb, ir, 2);
        if (verbose){
                hex_dump(dacb, 2, 2, "TX");
        	hex_dump(ir, 2, 2, "RX");
	}
}
static void monitor() {
	#define NW 10
	//uint8_t monitor_tx_set[] = {0x13, 0xFF};	// ADC repetitive mode, Temperature included
        uint8_t monitor_tx_set[] = {0x11, 0xFF};	// Temperature included.
	uint8_t twoz[] = {0x00, 0x00};
	uint8_t rx[NW*2];
        char *ir;
	int ii;
	ir = rx;
        transfer(monitor_tx_set, ir, 2);
	for(ii=0, ir=rx; ii<NW; ii++){
		transfer(twoz, ir, 2);
		ir +=2;
	}
	//hex_dump(rx, NW*2, NW*2, "RX");
	decode_rx(rx,NW,channels);
	guard(guard_adc_channel,guard_trip_level,guard_dac_channel);
}

static void print_usage(const char *prog)
{
	printf("Usage: %s [-DsbdlHOLC3m]\n", prog);
	puts("  -D --device   device to use (default /dev/spidev1.1)\n"
	     "  -s --speed    max speed (Hz)\n"
	     "  -d --delay    delay (usec)\n"
	     "  -b --bpw      bits per word \n"
	     "  -l --loop     loopback\n"
	     "  -H --cpha     clock phase\n"
	     "  -O --cpol     clock polarity\n"
	     "  -L --lsb      least significant bit first\n"
	     "  -C --cs-high  chip select active high\n"
	     "  -3 --3wire    SI/SO signals shared\n"
	     "  -v --verbose  Verbose (show tx buffer)\n"
	     "  -p            Send data (e.g. \"1234\\xde\\xad\")\n"
	     "  -N --no-cs    no chip select\n"
	     "  -R --ready    slave pulls low to pause\n"
/*&RA/	     "  -2 --dual     dual transfer\n"
	     "  -4 --quad     quad transfer\n"
*/
             "  -m --monitor  monitor\n"
            );
	exit(1);
}

static void parse_opts(int argc, char *argv[])
{
	while (1) {
		static const struct option lopts[] = {
			{ "device",  1, 0, 'D' },
			{ "speed",   1, 0, 's' },
			{ "delay",   1, 0, 'd' },
			{ "bpw",     1, 0, 'b' },
			{ "loop",    0, 0, 'l' },
			{ "cpha",    0, 0, 'H' },
			{ "cpol",    0, 0, 'O' },
			{ "lsb",     0, 0, 'L' },
			{ "cs-high", 0, 0, 'C' },
			{ "3wire",   0, 0, '3' },
			{ "no-cs",   0, 0, 'N' },
			{ "ready",   0, 0, 'R' },
//&RA/			{ "dual",    0, 0, '2' },
			{ "verbose", 0, 0, 'v' },
//&RA/			{ "quad",    0, 0, '4' },
                        { "monitor", 0, 0, 'm' },
			{ NULL, 0, 0, 0 },
		};
		int c;

		c = getopt_long(argc, argv, "D:s:d:b:lHOLC3NR24p:vm", lopts, NULL);

		if (c == -1)
			break;

		switch (c) {
		case 'D':
			device = optarg;
			break;
		case 's':
			speed = atoi(optarg);
			break;
		case 'd':
			delay = atoi(optarg);
			break;
		case 'b':
			bits = atoi(optarg);
			break;
		case 'l':
			mode |= SPI_LOOP;
			break;
		case 'H':
			mode |= SPI_CPHA;
			break;
		case 'O':
			mode |= SPI_CPOL;
			break;
		case 'L':
			mode |= SPI_LSB_FIRST;
			break;
		case 'C':
			mode |= SPI_CS_HIGH;
			break;
		case '3':
			mode |= SPI_3WIRE;
			break;
		case 'N':
			mode |= SPI_NO_CS;
			break;
		case 'v':
			verbose = 1;
			break;
		case 'R':
			mode |= SPI_READY;
			break;
		case 'p':
			input_tx = optarg;
			break;
/*&RA/		case '2':
			mode |= SPI_TX_DUAL;
			break;
		case '4':
			mode |= SPI_TX_QUAD;
			break;
*/
                case 'm':
			mode |= SPI_CPHA;
			monitoring=1;
                        break;
		default:
			print_usage(argv[0]);
			break;
		}
	}
	if (mode & SPI_LOOP) {
/*&RA/		if (mode & SPI_TX_DUAL)
			mode |= SPI_RX_DUAL;
		if (mode & SPI_TX_QUAD)
			mode |= SPI_RX_QUAD;
*/
	}
}

int main(int argc, char *argv[])
{
	int ret = 0;
	//int fd;
	int ii;
	uint8_t *tx,*it;
	uint8_t *rx,*ir;
	int size;

	parse_opts(argc, argv);

	fd = open(device, O_RDWR);
	if (fd < 0)
		pabort("can't open device");

	/*
	 * spi mode
	 */
/*&RA/	ret = ioctl(fd, SPI_IOC_WR_MODE32, &mode);
	if (ret == -1)
		pabort("can't set spi mode");

	ret = ioctl(fd, SPI_IOC_RD_MODE32, &mode);
	if (ret == -1)
		pabort("can't get spi mode");
*/
        ret = ioctl(fd, SPI_IOC_WR_MODE, &mode);
        if (ret == -1)
                pabort("can't set spi mode");

        ret = ioctl(fd, SPI_IOC_RD_MODE, &mode);
        if (ret == -1)
                pabort("can't get spi mode");
	/*
	 * bits per word
	 */
	ret = ioctl(fd, SPI_IOC_WR_BITS_PER_WORD, &bits);
	if (ret == -1)
		pabort("can't set bits per word");

	ret = ioctl(fd, SPI_IOC_RD_BITS_PER_WORD, &bits);
	if (ret == -1)
		pabort("can't get bits per word");

	/*
	 * max speed hz
	 */
	ret = ioctl(fd, SPI_IOC_WR_MAX_SPEED_HZ, &speed);
	if (ret == -1)
		pabort("can't set max speed hz");

	ret = ioctl(fd, SPI_IOC_RD_MAX_SPEED_HZ, &speed);
	if (ret == -1)
		pabort("can't get max speed hz");

	if(verbose) {
	  printf("spi mode: 0x%x\n", mode);
	  printf("bits per word: %d\n", bits);
	  printf("max speed: %d Hz (%d KHz)\n", speed, speed/1000);
	}
	while(1)
	{
        if (monitoring) monitor();
	else {
	if (input_tx) {
		size = strlen(input_tx+1);
		if (size)
		{
		tx = malloc(size);
		rx = malloc(size);
		size = unescape((char *)tx, input_tx, size);
		//transfer(tx, rx, size);
                //split transfer into 2-byte chunks, needed for ad5592
		for(it=tx,ir=rx,ii=0; ii<size; ii+=2)
		{
			transfer(it, ir, 2);
			it += 2; ir += 2;
		}//
		}
	} else {
		size = sizeof(default_tx);
                tx = (uint8_t*) &default_tx;
                rx = (uint8_t*) &default_rx;
		transfer(tx, rx, size);
	}
	if (verbose)    hex_dump(tx, size, 16, "TX");
	hex_dump(rx, size, 16, "RX");
        if( tx != (uint8_t*) &default_tx)
	{
		free(rx);
		free(tx);
	}
	}
	if(!monitoring) break;
	else sleep(1);
	}
	close(fd);

	return ret;
}
