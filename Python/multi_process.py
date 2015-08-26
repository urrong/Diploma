import numpy as np
import time
import httplib
import urllib
from cStringIO import StringIO
from multiprocessing import Process, Queue, Lock
from scipy import misc
from scipy.ndimage import measurements
import scipy.io as sio

#minRGB = np.array([227, 243, 0])
#maxRGB = np.array([255, 255, 188])
minRGB = np.array([244, 255, 0])
maxRGB = np.array([255, 255, 182])

class ImagePull(Process):
	def __init__(self, queue, ioLock, params):
		super(ImagePull, self).__init__()
		self.queue = queue
		self.ioLock = ioLock
		self.ip = params["ip"]
		self.name = params["name"]
		self.httpConn = httplib.HTTPConnection(self.ip)
		self.daemon = True
		
		#set camera attributes
		print self.name + ": setting attributes ..."
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
		print self.name + ": done\n"
	
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
				
				img = misc.imresize(im, 0.5)
				im = img.copy()
				
				im = np.logical_and(minRGB <= im[:, :], maxRGB >= im[:, :])
				im = np.all(im, axis = 2)
				im = im.astype("int64")
				center = measurements.center_of_mass(im)
				
				data = data[e + 2:]
				
				if not np.isnan(center[0]):
					self.ioLock.acquire()
					print "process", self.name, "-", center
					self.ioLock.release()

if __name__ == "__main__":
	camParams = []
	
	#ip, pan, tilt
	camAttributes = [("192.168.1.131", 120, 30),
					 ("192.168.1.129", 111, 30),
					 ("192.168.1.126", 159, 30),
					 ("192.168.1.116", 42, 24)];
		   
	#intrinsics, extrinsics, radial
	matParams = sio.loadmat("cameraParams_py")
	for i in range(4):
		camParams.append({"intrinsics": matParams["params"][0][i][0],
						  "extrinsics": matParams["params"][0][i][1],
						  "radial": matParams["params"][0][i][2],
						  "brightness": 4766,
						  "speed": 100,
						  "ip": camAttributes[i][0],
						  "pan": camAttributes[i][1],
						  "tilt": camAttributes[i][2],
						  "name": "camera" + str(i + 1)
						 });
	
	queues = []
	processes = []
	ioLock = Lock()
	for param in camParams:
		q = Queue()
		p = ImagePull(q, ioLock, param)
		queues.append(q)
		processes.append(p)
	
	for p in processes:
		p.start()
	
	time.sleep(60)
