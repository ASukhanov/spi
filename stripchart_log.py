#!/bin/bash
'''
Dynamic chart of a changing log file 
'''

fn='/tmp/dadc.log'
NCurves = 9
NPoints = 1000

import time
from pyqtgraph.Qt import QtGui, QtCore
import numpy as np
import pyqtgraph as pg

#### PyQt GUI setup ###########################################################
app = QtGui.QApplication([])
win = pg.GraphicsWindow(title="Stripchart")
win.resize(NPoints,600)

# Enable antialiasing for prettier plots
pg.setConfigOptions(antialias=True)

randplot = win.addPlot(title="Data")

''' TODO add colored legend
for ii in range(NCurves):
  label = pg.TextItem("test", anchor=(0.1+ii/10., 0.5))
  label.setParentItem(randplot)
'''

grf = []
for ii in range(NCurves):
  grf.append(randplot.plot(pen=(ii,NCurves)))

# generate random samples
rndm = np.empty((NCurves,NPoints),dtype=np.int)
for ii in range(NCurves):
  rndm[ii] = np.random.random_integers(0,10,NPoints)

data = np.zeros((NCurves,NPoints),dtype=np.int)

f = open(fn)
p = 0
step = 0
pastdata = True
d = [0 for ii in range(NCurves)]

def update():
    global f,p,step,d
    step = (step + 1) % NPoints
    f.seek(p)
    latest_data = f.readline()
    p = f.tell()
    if len(latest_data)==0:
      return
    #print('['+latest_data+']')
    try: 
      fday,ftime,d[0],d[1],d[2],d[3],d[4],d[5],d[6],d[7],d[8] = latest_data[:65].split(' ')
    except:
      print(latest_data),
      return
    #
    # roll and update data arrays
    for ii in range(NCurves):
      data[ii][1:] = data[ii][:-1]
      #data[ii][:1] = rndm[ii][step] + ii*10
      data[ii][:1] = d[ii]
    #
    # update plots 
    for ii in range(NCurves):
      grf[ii].setData(data[ii])
        
timer = QtCore.QTimer()
timer.timeout.connect(update)
timer.start(50)

## Start Qt event loop unless running in interactive mode or using pyside.
if __name__ == '__main__':
  import sys
  if (sys.flags.interactive != 1) or not hasattr(QtCore, 'PYQT_VERSION'):
      QtGui.QApplication.instance().exec_()
  print('Shutting down')
