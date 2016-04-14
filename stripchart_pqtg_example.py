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

grf = []
for ii in range(NCurves):
  grf.append(randplot.plot(pen=(ii,NCurves)))

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