'''
9-line Stripchart using rollling array 
'''
import time

from pyqtgraph.Qt import QtGui, QtCore
import numpy as np
import pyqtgraph as pg

NCurves = 9
NPoints = 1000

#### PyQt GUI setup ###########################################################
app = QtGui.QApplication([])
win = pg.GraphicsWindow(title="Stripchart")
win.resize(NPoints,600)

# Enable antialiasing for prettier plots
pg.setConfigOptions(antialias=True)

randplot = win.addPlot(title="Data")

ii = 0
curve0 = randplot.plot(pen=(ii,NCurves))
ii += 1
curve1 = randplot.plot(pen=(ii,NCurves)) 
ii += 1
curve2 = randplot.plot(pen=(ii,NCurves)) 
ii += 1
curve3 = randplot.plot(pen=(ii,NCurves)) 
ii += 1
curve4 = randplot.plot(pen=(ii,NCurves))
ii += 1
curve5 = randplot.plot(pen=(ii,NCurves))
ii += 1
curve6 = randplot.plot(pen=(ii,NCurves))
ii += 1
curve7 = randplot.plot(pen=(ii,NCurves))
ii += 8
curve8 = randplot.plot(pen=(ii,NCurves))

# generate random samples
rndm = np.empty((NCurves,NPoints),dtype=np.int)
for ii in range(NCurves):
  rndm[ii] = np.random.random_integers(0,10,NPoints)

data = np.zeros((NCurves,NPoints),dtype=np.int)

step = 0
def update():
    global step
    step = (step + 1) % NPoints
    #
    # roll and update data arrays
    for ii in range(NCurves):
      data[ii][1:] = data[ii][:-1]
      data[ii][:1] = rndm[ii][step] + ii*10
    #
    # update plots 
    ii = 0
    curve0.setData(data[ii])
    ii += 1
    curve1.setData(data[ii])
    ii += 1
    curve2.setData(data[ii])
    ii += 1
    curve3.setData(data[ii])
    ii += 1
    curve4.setData(data[ii])
    ii += 1
    curve5.setData(data[ii])
    ii += 1
    curve6.setData(data[ii])
    ii += 1
    curve7.setData(data[ii])
    ii += 1
    curve8.setData(data[ii])
    
timer = QtCore.QTimer()
timer.timeout.connect(update)
timer.start(50)

## Start Qt event loop unless running in interactive mode or using pyside.
if __name__ == '__main__':
  import sys
  if (sys.flags.interactive != 1) or not hasattr(QtCore, 'PYQT_VERSION'):
      QtGui.QApplication.instance().exec_()
  print('Shutting down')
