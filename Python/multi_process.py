import numpy as np
import time
import httplib
import urllib
from cStringIO import StringIO
from multiprocessing import Process, Array, Lock
from scipy import misc
from scipy.ndimage import measurements
import scipy.io as sio

#minRGB = np.array([227, 243, 0])
#maxRGB = np.array([255, 255, 188])
minRGB = np.array([200, 200, 0])
maxRGB = np.array([255, 255, 180])

class ImagePull(Process):
	def __init__(self, cArray, ioLock, params):
		super(ImagePull, self).__init__()
		self.cArray = cArray
		self.ioLock = ioLock
		self.ip = params["ip"]
		self.name = params["name"]
		self.httpConn = httplib.HTTPConnection(self.ip)
		self.resize = params["resize"]
		self.daemon = True
		
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
		
		while True:
			data += stream.read(4096)
			s = data.find('\xff\xd8')
			e = data.find('\xff\xd9')
			if e != -1 and e != -1:
				im = misc.imread(StringIO(data[s:e+2]))
				if self.resize != 1.0:
					im = misc.imresize(im, self.resize)
				
				im = np.logical_and(minRGB <= im[:, :], maxRGB >= im[:, :])
				im = np.all(im, axis = 2)
				im = im.astype("int64")
				center = measurements.center_of_mass(im)
				if np.isnan(center[0]):
					center = (0.0, 0.0)
				
				data = data[e + 2:]
				
				with self.cArray.get_lock():
					#interchange coordinates
					self.cArray[0] = center[1] / self.resize
					self.cArray[1] = center[0] / self.resize
				
				time.sleep(0.0001)

if __name__ == "__main__":
	camParams = []
	
	#ip, pan, tilt
	camAttributes = [("192.168.1.131", 120, 30),
					 ("192.168.1.129", 111, 30),
					 ("192.168.1.126", 159, 30),
					 ("192.168.1.116", 42, 24)];
	
	nCams = len(camAttributes)
		   
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
						  "resize": 0.5
						 });
	
	cArrays = []
	processes = []
	ioLock = Lock()
	for param in camParams:
		arr = Array('d', [0.0, 0.0])
		p = ImagePull(arr, ioLock, param)
		cArrays.append(arr)
		processes.append(p)
	
	print "starting processes"
	for p in processes:
		p.start()
	
	while True:
		C = np.zeros((12, 4))
		numFound = 0
		
		for i in range(nCams):
			foundMarker = False
			x = [0.0, 0.0, 1.0] #image 
			with cArrays[i].get_lock():
				if cArrays[i][0]:
					x[0] = cArrays[i][0]
					x[1] = cArrays[i][1]
					foundMarker = True
			
			if foundMarker:
				#print "camera" + str(i+1), "- %.2f %.2f" % (x[0], x[1])
				numFound += 1
				cross = np.mat([[0, -x[2], x[1]],
								[x[2], 0, -x[0]],
								[-x[1], x[0], 0]])
				C[i*3:i*3+3, :] = cross.dot(camParams[i]["intrinsics"]).dot(camParams[i]["extrinsics"])
		
		if numFound > 1:
			u, s, v = np.linalg.svd(C)
			p = v.T[:, 3]
			p /= p[3]
			print p[:3]