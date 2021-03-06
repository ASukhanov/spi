#!/usr/bin/python
# Dynamic chart 
fn='/tmp/dadc.log' 
#version 1 2015-07-21

import pylab as pl

NP=1000
NG=9
YMAX=3000

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
  Y[ii][0]=YMAX
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
    for nn in range(NG):
      #Y[nn][ii%NP] = pl.random()*10.+100.*nn
      Y[nn][ii%NP] = d[nn]
      Y[nn][(ii+1)%NP] = 0
      grf[nn].set_ydata(Y[nn])
 
    #pl.draw()
    fig.canvas.draw()

