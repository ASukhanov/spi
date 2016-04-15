#!/usr/bin/python
version = 'v2 2016-04-14 option -t'
def usage():
  print('Dynamic chart of a changing log file. '+version)
  print(' usage: '+sys.argv[0]+ ' [-t N] [-m]')
  print('   Option -t: start logging N hours after beginning (N>0) or before the end (N<0) of the file.')
  print('   Option -m: Display means')

# Setting
fn='/tmp/dadc.log'
NCurves = 9
NPoints = 1000
Logline_length = 64
Tail = True
labels = ('00:00:00','BMon','IBHR','BPrg','IBLR','ad4','ad5','AVDD','DVDD','Temp')
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
  opts,args = getopt.getopt(sys.argv[1:], 'hmt:', ["help", "mean", "time"])
except getopt.GetoptError as err:
        # print help information and exit:
        print str(err) # will print something like "option -a not recognized"
        usage()
        sys.exit(2)
fpos = 0
for o, a in opts:
        if o == "-t":
            fpos = int(3600*float(a)*Logline_length)
            #print('fpos='+str(fpos))
            Tail = False
        elif o == "-m":
            Means = True
        elif o in ("-h", "--help"):
            usage()
            sys.exit()
        else:
            assert False, "unhandled option "

#### PyQt GUI setup ###########################################################
app = QtGui.QApplication([])
win = pg.GraphicsWindow(title="RPi Bias Source & NanoAmmeter")
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
step = 0

# Open file and set position
f = open(fn,'rU')
if Tail:
  fpos = f.seek(0,2)
  fpos = f.tell()
else:
  whence = 0 if fpos>=0 else 2
  print
  f.seek(fpos, whence)
print('file '+fn+' opened and positioned to '+str(f.tell()))

# Define update function
def update():
    # get new data in data[]
    global f,step,d,Tail,fpos,mean
    for  lines in range(NPoints):
      step = (step + 1) % NPoints
      if Tail:
        f.seek(fpos)
      latest_data = f.readline()
      if Tail:
        fpos = f.tell()
      #print('l='+str(len(latest_data)))
      if len(latest_data)<Logline_length: #too short
        if len(latest_data)==0: # reached end of file
          if not Tail:
            print('End of file reached.')
            Tail = True
            fpos = f.tell()
        time.sleep(1)
        return
      #print(latest_data)
      try: 
        fday,ftime,d[0],d[1],d[2],d[3],d[4],d[5],d[6],d[7],d[8] = latest_data.split(' ')
      except:
        print(latest_data),
        return
      label[0].setText(ftime)
      #
      # roll and update data arrays
      if Tail:
        for ii in range(NCurves):
          data[ii][1:] = data[ii][:-1]
          data[ii][:1] = d[ii]
        break
      else:
        for ii in range(NCurves):
          data[ii][step] = d[ii]
    #
    # update plots with new data
    for ii in range(NCurves):
      grf[ii].setData(data[ii])
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
