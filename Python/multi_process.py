import numpy as np
import time
import urllib
from cStringIO import StringIO
from multiprocessing import Process, Queue, Lock
from scipy import misc
from scipy.ndimage import measurements

minRGB = np.array([227, 243, 0])
maxRGB = np.array([255, 255, 188])

class ImagePull(Process):
	def __init__(self, queue, ioLock, ip):
		super(ImagePull, self).__init__()
		self.queue = queue
		self.ioLock = ioLock
		self.ip = ip
		self.daemon = True
	
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
				
				self.ioLock.acquire()
				print "process", self.name, "-", center
				self.ioLock.release()

if __name__ == "__main__":
	cameras = ["192.168.1.131", 
			   "192.168.1.128",
			   "192.168.1.121",
			   "192.168.1.114"];
	queues = []
	processes = []
	ioLock = Lock()
	for ip in cameras:
		q = Queue()
		p = ImagePull(q, ioLock, ip)
		queues.append(q)
		processes.append(p)
		p.start()
	
	time.sleep(10)
