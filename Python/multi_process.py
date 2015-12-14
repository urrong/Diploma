import numpy as np
import sys
import cv2
import time
import httplib
import urllib
from cStringIO import StringIO
from multiprocessing import Process, Array, Lock
from scipy import misc
from scipy.ndimage import measurements
import scipy.io as sio
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D
import pickle

#interrupt workaround
# Load the DLL manually to ensure its handler gets
# set before our handler.
import os
import imp
import ctypes
import win32api
import thread

basepath = imp.find_module('numpy')[1]
ctypes.CDLL(os.path.join(basepath, 'core', 'libmmd.dll'))
ctypes.CDLL(os.path.join(basepath, 'core', 'libifcoremd.dll'))

# Now set our handler for CTRL_C_EVENT. Other control event 
# types will chain to the next handler.
def handler(dwCtrlType, hook_sigint=thread.interrupt_main):
    if dwCtrlType == 0: # CTRL_C_EVENT
        hook_sigint()
        return 1 # don't chain to the next handler
    return 0 # chain to the next handler

win32api.SetConsoleCtrlHandler(handler, 1)

minRGB = np.array([220, 220, 0])
maxRGB = np.array([255, 255, 200])
#minRGB = np.array([200, 200, 0])
#maxRGB = np.array([255, 255, 180])

class ImagePull(Process):
	def __init__(self, cArray, ioLock, params):
		super(ImagePull, self).__init__()
		self.cArray = cArray
		self.ioLock = ioLock
		self.ip = params["ip"]
		self.name = params["name"]
		self.httpConn = httplib.HTTPConnection(self.ip)
		self.scale = params["scale"]
		self.intrinsics = params["intrinsics"]
		self.extrinsics = params["extrinsics"]
		self.distorsion = np.array([params["radial"][0][0], params["radial"][0][1], 0, 0])
		
		self.daemon = True
		self.scaledIntrinsics = self.intrinsics.copy()
		self.scaledIntrinsics *= self.scale
		self.scaledIntrinsics[2, 2] = 1
		
		#set camera attributes
		print self.name + ": setting attributes"
		self.CGIquery("brightness=" + str(params["brightness"]))
		self.CGIquery("speed=" + str(params["speed"]))
		self.CGIquery("pan=" + str(params["pan"]))
		self.CGIquery("tilt=" + str(params["tilt"]))
		finishedPan = False
		finishedTilt = False
		while not finishedPan or not finishedTilt:
			pos = self.CGIquery("query=position").split("\n")
			finishedPan = float(pos[0].split("=")[1]) == float(params["pan"])
			finishedTilt = float(pos[1].split("=")[1]) == float(params["tilt"])
	
	def CGIquery(self, query):
		self.httpConn.request("GET", "/axis-cgi/com/ptz.cgi?" + query)
		return self.httpConn.getresponse().read()
	
	def run(self):
		stream = urllib.urlopen("http://" + self.ip + "/mjpg/video.mjpg")
		data = ""
		
		start = time.time()
		numPics = 0
		print self.name, "started"
		while True:
			data += stream.read(4096)
			s = data.find('\xff\xd8')
			e = data.find('\xff\xd9')
			if e != -1 and e != -1:
				#numPics += 1
				#self.ioLock.acquire()
				#print self.name, numPics / (time.time() - start)
				#self.ioLock.release()
				
				timestamp = time.time()
				im = misc.imread(StringIO(data[s:e+2]))
				
				size = (int(im.shape[1] * self.scale), int(im.shape[0] * self.scale))
				mx, my = cv2.initUndistortRectifyMap(self.intrinsics, self.distorsion, None, self.scaledIntrinsics, size, cv2.CV_32FC1)
				im = cv2.remap(im, mx, my, cv2.INTER_LINEAR)
				#misc.imsave(self.name + "2.jpg", im)
				#plt.imshow(im)
				#plt.show()
				
				im = cv2.inRange(im, minRGB, maxRGB, im)
				moments = cv2.moments(im, binaryImage = True)
				if moments["m00"]:
					center = (moments["m10"] / moments["m00"], moments["m01"] / moments["m00"])
				else:
					center = (0.0, 0.0)
				
				data = data[e + 2:]
				
				with self.cArray.get_lock():
					self.cArray[0] = center[0] / self.scale
					self.cArray[1] = center[1] / self.scale
					self.cArray[2] = timestamp
				
				
				time.sleep(0.0001)

if __name__ == "__main__":
	camParams = []
	
	#ip, pan, tilt
	camAttributes = [("192.168.1.131", 120, 30),
					 ("192.168.1.127", 111, 30),
					 ("192.168.1.121", 159, 30),
					 ("192.168.1.114", 42, 24)];
	
	#nCams = len(camAttributes)
	nCams = 4
	
	#intrinsics, extrinsics, radial
	matParams = sio.loadmat("cameraParams_py")
	for i in range(nCams):
		camParams.append({"intrinsics": matParams["params"][0][i][0],
						  "extrinsics": matParams["params"][0][i][1],
						  "radial": matParams["params"][0][i][2],
						  "brightness": 939,
						  "speed": 100,
						  "ip": camAttributes[i][0],
						  "pan": camAttributes[i][1],
						  "tilt": camAttributes[i][2],
						  "name": "camera" + str(i + 1),
						  "scale": 0.5
						 });
	
	cArrays = []
	processes = []
	ioLock = Lock()
	for param in camParams:
		arr = Array('d', [0.0, 0.0, 0.0])
		p = ImagePull(arr, ioLock, param)
		cArrays.append(arr)
		processes.append(p)
	
	for p in processes:
		p.start()
	
	prevImagePoints = []
	for i in range(nCams):
		#third component is timestamp
		prevImagePoints.append(np.zeros(3))
	
	components = []
	line = []
	prevPoint = np.array([0.0, 0.0, 0.0])
	#markerPoints = []
	
	try:
		while True:
			C = np.zeros((nCams * 3, 4))
			numFound = 0
			#timestamps = [0] * nCams;
			t = time.time();
			markers = []
			for i in range(nCams):
				foundMarker = False
				x = [0.0, 0.0, 1.0] #image point
				with cArrays[i].get_lock():
					if cArrays[i][0]:
						x[0] = cArrays[i][0]
						x[1] = cArrays[i][1]
						foundMarker = True
						#linear interpolation
						if prevImagePoints[i][0]:
							x[0] = x[0] + (x[0] - prevImagePoints[i][0]) * (t - cArrays[i][2])
							x[1] = x[1] + (x[1] - prevImagePoints[i][1]) * (t - cArrays[i][2])
							#TODO
					else:
						prevImagePoints[i][0] = 0;
						prevImagePoints[i][1] = 0;
				
				if foundMarker:
					markers.append(x)
					numFound += 1
					cross = np.mat([[0, -x[2], x[1]],
									[x[2], 0, -x[0]],
									[-x[1], x[0], 0]])
					C[i*3:i*3+3, :] = cross.dot(camParams[i]["intrinsics"]).dot(camParams[i]["extrinsics"])
			
			if numFound > 1:
				#markerPoints.append(markers)
				u, s, v = np.linalg.svd(C)
				p = v.T[:, 3]
				p = (p / p[3])[:3]
				d = np.linalg.norm(prevPoint - p)
				if d > 0.0 and d < 15.0:
					line.append(p)
				elif d > 15.0:
					components.append(line)
					line = []
				if d > 0.0:
					prevPoint = p
					print p, numFound
			time.sleep(0.0001)
	except KeyboardInterrupt:
		pass
	#pickle.dump(markerPoints, open("marker_points_path.pkl", "wb"))
	components.append(line)
	#pickle.dump(components, open("points.pkl", "wb"))
	
	print len(components)
	
	#draw paths
	figure = plt.figure()
	axes = figure.add_subplot(111, projection = "3d")
	
	#bounding box for equal axis
	for point in np.diag(200 * np.ones(3)):
		axes.plot([point[0]], [point[1]], [point[2]], 'w')
	
	for line in components:
		if len(line) > 1:
			line = np.array(line)
			axes.plot(line[:, 0], line[:, 1], line[:, 2], "g-", linewidth=3)
	plt.show()