import urllib
from PIL import Image
import numpy as np
from scipy import misc
from scipy.ndimage.measurements import *
from scipy.ndimage.filters import *
import matplotlib.pyplot as plt
import matplotlib
from cStringIO import StringIO

import time

IP = "192.168.1.110"
#minHSV = np.array([0.1520, 0.3840, 0.8627])
#maxHSV = np.array([0.1801, 1.0, 1.0])
minHSV = np.array([200, 200, 0])
maxHSV = np.array([255, 255, 50])

stream = urllib.urlopen("http://" + IP + "/mjpg/video.mjpg")
data = ""

figure, axes = plt.subplots()
tmpImg = np.zeros((576, 704))
tmpImg[0, 0] = 1;
figImg = axes.imshow(tmpImg, cmap = plt.cm.gray)
figure.show()

#for i in range(2000):
while True:
	data += stream.read(4096)
	s = data.find('\xff\xd8')
	e = data.find('\xff\xd9')
	if e != -1 and e != -1:
		im = misc.imread(StringIO(data[s:e+2]))
		im = np.fliplr(im)
		
		#im = matplotlib.colors.rgb_to_hsv(im / 255.0)
		im = np.logical_and(minHSV <= im[:, :], maxHSV >= im[:, :])
		im = np.all(im, axis = 2)
		im = im.astype("int64")
		center = center_of_mass(im)
		print center
		
		#axes.plot(center[1], center[0], "ro")
		#figImg.set_data(im)
		#figure.canvas.draw()
		
		data = data[e + 2:]
		