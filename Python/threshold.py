import urllib
import numpy as np
from scipy import misc
from scipy.ndimage import measurements
#import matplotlib
import matplotlib.pyplot as plt
from cStringIO import StringIO
import time

IP = "192.168.1.131"
#minHSV = np.array([0.1520, 0.3840, 0.8627])
#maxHSV = np.array([0.1801, 1.0, 1.0])
minHSV = np.array([227, 243, 0])
maxHSV = np.array([255, 255, 188])

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
		start = time.time()
		im = misc.imread(StringIO(data[s:e+2]))
		img = misc.imresize(im, 0.5)
		im = img.copy()
		print time.time() - start 
		#im = matplotlib.colors.rgb_to_hsv(im / 255.0)
		im = np.logical_and(minHSV <= im[:, :], maxHSV >= im[:, :])
		im = np.all(im, axis = 2)
		im = im.astype("int64")
		
		center = measurements.center_of_mass(im)
		print center
		
		axes.plot(center[1] * 2, center[0] * 2, "ro")
		figImg.set_data(img)
		figure.canvas.draw()
		
		data = data[e + 2:]
		