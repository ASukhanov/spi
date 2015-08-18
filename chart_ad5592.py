#!/usr/bin/python
# Dynamic chart of 9 reading from the changing log file
fn='/tmp/dadc.log' 
#version 1 2015-07-21
#version 2 2015-08-17  pastdata feature added

import pylab as pl
import time

#MAXY=4100
MAXY=1000
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
pastdata = True
while True:
    f.seek(p)
    latest_data = f.readline()
    p = f.tell()
    if len(latest_data)==0:
      pastdata = False
      pl.pause(1) # provides interactive chart control, but takes more CPU time
      #time.sleep(1) #this takes much less of CPU but no interactive control of the chart
      continue
    ii += 1
    fday,ftime,d[0],d[1],d[2],d[3],d[4],d[5],d[6],d[7],d[8] = latest_data.split(' ')
    
    #scale some channels
    d[3] = str(4096 - int(d[3])) # voltage drop on D2 shottky
    d[5] = str(2500 - int(d[5])) # 2.5V
    d[7] = str(2500 - int(d[7])) # 2.5V
    #print(d)

    for nn in range(NG):
      Y[nn][ii%NP] = d[nn]
      Y[nn][(ii+1)%NP] = 0
      grf[nn].set_ydata(Y[nn])
    if pastdata and ii%NP == 0:
      print(fday,ftime,d)
      pl.draw()
      #fig.canvas.draw()
      #time.sleep(1) 
    if  not pastdata:
      pl.draw()
      #fig.canvas.draw()
