#!/bin/bash
version = 'v1 2016-04-13'
def usage():
  print('Dynamic chart of a changing log file. '+version+', usage: '+sys.argv[0]+ ' [-b]')

# Setting
fn='/tmp/dadc.log'
NCurves = 9
NPoints = 1000
Tail = True
labels = ('BMon','IBHR','BPrg','IBLR','ad4','ad5','AVDD','DVDD','Temp')

import sys
import getopt
import time
from pyqtgraph.Qt import QtGui, QtCore
import numpy as np
import pyqtgraph as pg

try:
  opts,args = getopt.getopt(sys.argv[1:], 'hb', ["help", "beginning"])
except getopt.GetoptError as err:
        # print help information and exit:
        print str(err) # will print something like "option -a not recognized"
        usage()
        sys.exit(2)
for o, a in opts:
        if o == "-b":
            Tail = False
        elif o in ("-h", "--help"):
            usage()
            sys.exit()
        else:
            assert False, "unhandled option"

#### PyQt GUI setup ###########################################################
app = QtGui.QApplication([])
win = pg.GraphicsWindow(title="RPi Bias Source & NanoAmmeter")
win.resize(NPoints,600)

# Enable antialiasing for prettier plots
pg.setConfigOptions(antialias=True)

for ii in range(NCurves):
  label = pg.LabelItem(labels[ii],justify='right',bold=True,size='14pt')
  label.setText(labels[ii],color=pg.intColor(ii))
  win.addItem(label,row=0,col=ii)
  #win.addLabel(labels[ii],row=0,col=ii,color=pg.intColor(ii))

randplot = win.addPlot(row=1,col=0,colspan=NCurves)

grf = []
for ii in range(NCurves):
  grf.append(randplot.plot(pen=(ii,NCurves)))

# generate random samples
rndm = np.empty((NCurves,NPoints),dtype=np.int)
for ii in range(NCurves):
  rndm[ii] = np.random.random_integers(0,10,NPoints)

data = np.zeros((NCurves,NPoints),dtype=np.int)

f = open(fn,'rU')
p = 0
step = 0
pastdata = True
d = [0 for ii in range(NCurves)]


def update():
    global f,p,step,d
    for  lines in range(100):
      step = (step + 1) % NPoints
      if Tail:
        f.seek(-(65+5),2)
        latest_data = f.readlines()[-1].decode()
      else:
        latest_data = f.readline()
      #print('l='+str(len(latest_data)))
      #if Tail:
      #  print('tell')
      #  p = f.tell()
      if len(latest_data)<10: #too short
        return
      #print('['+latest_data+']'),
      try: 
        fday,ftime,d[0],d[1],d[2],d[3],d[4],d[5],d[6],d[7],d[8] = latest_data[:65].split(' ')
      except:
        print(latest_data),
        return
      #print(ftime)
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
      if Tail:
        return
        
timer = QtCore.QTimer()
timer.timeout.connect(update)
if Tail:
  timer.start(1000)
else:
  timer.start(100)

## Start Qt event loop unless running in interactive mode or using pyside.
if __name__ == '__main__':
  import sys
  if (sys.flags.interactive != 1) or not hasattr(QtCore, 'PYQT_VERSION'):
      QtGui.QApplication.instance().exec_()
  print('Shutting down')
