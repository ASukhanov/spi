#!/usr/bin/python
version = 'v2 2016-04-14 option -t'
def usage():
  print('Dynamic chart. '+version)
  print(' usage: '+sys.argv[0]+ ' [-c N] [-m]')
  print('   Options: -m: Display means, -c Plot in chunks of N samples.')

# Setting
NCurves = 9
NPoints = 1000
Chunks = 1
labels = ('00:00:00','ADC0','ADC1','ADC2','ADC3','ADC4','ADC5','ADC6','ADC7','Temp')
Means = False
MeanRange = 10
means = ('Means:','?','?','?','?','?','?','?','?','?')

import sys
import getopt
import time
from pyqtgraph.Qt import QtGui, QtCore
import numpy as np
import pyqtgraph as pg

try:
  opts,args = getopt.getopt(sys.argv[1:], 'hmc:', ["help", "mean", "time"])
except getopt.GetoptError as err:
        # print help information and exit:
        print str(err) # will print something like "option -a not recognized"
        usage()
        sys.exit(2)
for o, a in opts:
        if o in ('-m', '--mean'):
            Means = True
        elif o in ('-c', '--chunk'):
            Chunks = int(a)
        elif o in ("-h", "--help"):
            usage()
            sys.exit()
        else:
            assert False, "unhandled option "

#### PyQt GUI setup ###########################################################
app = QtGui.QApplication([])
win = pg.GraphicsWindow(title="Stripchart example")
win.resize(NPoints,600)

# Enable antialiasing for prettier plots
pg.setConfigOptions(antialias=True)

row = 0
# Place labels
label = []
for ii in range(NCurves+1):
  label.append(pg.LabelItem(labels[ii],justify='right',bold=True,size='14pt'))
  if ii:
    tcolor = pg.intColor(ii-1)
  else:
    tcolor = 'w'
  label[ii].setText(labels[ii],color=tcolor)
  win.addItem(label[ii],row=row,col=ii)

# Place means
if Means:
  mean = []
  row = row + 1
  for ii in range(NCurves+1):
    mean.append(pg.LabelItem(means[ii],justify='right',bold=True,size='14pt'))
    win.addItem(mean[ii],row=row,col=ii)

# Add curves
row = row + 1
randplot = win.addPlot(row,col=0,colspan=NCurves+1)
grf = []
for ii in range(NCurves):
  grf.append(randplot.plot(pen=(ii,NCurves)))

data = np.zeros((NCurves,NPoints),dtype=np.int)
d = [0 for ii in range(NCurves)]

rndm = np.empty((NCurves,NPoints),dtype=np.int)
for ii in range(NCurves):
  rndm[ii] = np.random.random_integers(0,10,NPoints)

step = 0
# Define update function
def update():
    # get new data in data[]
    global step,data,grf,Means,NCurves,NPoints
    for chunk in range(Chunks):
      step = (step + 1) % NPoints
      # roll and update data arrays
      for ii in range(NCurves):
        data[ii][1:] = data[ii][:-1]
        data[ii][:1] = rndm[ii][step] + ii*10
    #
    # update plots
    for ii in range(NCurves):
      grf[ii].setData(data[ii])
    #grf[ii].setPos(step,0)
    if Means:
      for ii in range(NCurves):
        mean[ii+1].setText(str(np.mean(data[ii][:MeanRange])))

timer = QtCore.QTimer()
timer.timeout.connect(update)
timer.start(50)

## Start Qt event loop unless running in interactive mode or using pyside.
if __name__ == '__main__':
  import sys
  if (sys.flags.interactive != 1) or not hasattr(QtCore, 'PYQT_VERSION'):
      QtGui.QApplication.instance().exec_()
  print('Shutting down')
