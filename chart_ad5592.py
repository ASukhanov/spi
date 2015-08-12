#!/usr/bin/python
# Dynamic chart of 9 reading from the changing log file
fn='/tmp/dadc.log' 
#version 1 2015-07-21

import pylab as pl

MAXY=4100
NP=1000
NG=9
X = pl.arange(0,NP,1)
sp = []
Y = []
grf = []
d = [0 for ii in range(9)]

pl.ion()
fig = pl.figure()

for ii in range(NG):
  sp.append(fig.add_subplot(111))
  Y.append(pl.linspace(0,0,NP))
  Y[ii][0]=MAXY
  grf.append(sp[ii].plot(X,Y[ii])[0]) 

f = open(fn)
p = 0

ii=0
while True:
    f.seek(p)
    latest_data = f.readline()
    p = f.tell()
    if len(latest_data)==0:
      pl.pause(1)
      continue
    ii += 1
    day,time,d[0],d[1],d[2],d[3],d[4],d[5],d[6],d[7],d[8] = latest_data.split(' ')
    
    #clear unused channels
    #d[7] = 0

    #scale channels
    d[7] = str(4096 - int(d[7]))	# voltage drop on D2 shottky

    for nn in range(NG):
      Y[nn][ii%NP] = d[nn]
      Y[nn][(ii+1)%NP] = 0
      grf[nn].set_ydata(Y[nn])
    #pl.draw()
    fig.canvas.draw()

