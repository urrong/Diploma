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

if __name__ == "__main__":
	camParams = []
	nCams = 4
	
	matParams = sio.loadmat("cameraParams_py")
	for i in range(nCams):
		camParams.append({"intrinsics": matParams["params"][0][i][0],
						  "extrinsics": matParams["params"][0][i][1],
						  "radial": matParams["params"][0][i][2],
						 });
	
	
	
	points = pickle.load(open("marker_points_path.pkl", "rb"))
	
	"""useCam = [[0, 1],
			  [0, 2],
			  [0, 3],
			  [1, 2],
			  [1, 3],
			  [2, 3],
			  [0, 1, 2],
			  [0, 1, 3],
			  [0, 2, 3],
			  [1, 2, 3],
			  [0, 1, 3, 2]]"""
			  
	useCam = [[0, 3]]
	
	#fullComponents = [[], [], [], [], [], [], [], []]
	for use in useCam:
		components = []
		line = []
		prevPoint = np.array([0.0, 0.0, 0.0])
		for P in points:
			C = np.zeros((nCams * 3, 4))
			
			for i in range(nCams):
				if i in use:
					x = P[i]
					if i == 0:
						x[0] += 1.5
						x[1] += 1.5
					cross = np.mat([[0, -x[2], x[1]],
									[x[2], 0, -x[0]],
									[-x[1], x[0], 0]])
					C[i*3:i*3+3, :] = cross.dot(camParams[i]["intrinsics"]).dot(camParams[i]["extrinsics"])
			
			u, s, v = np.linalg.svd(C)
			p = v.T[:, 3]
			p = (p / p[3])[:3]
			d = np.linalg.norm(prevPoint - p)
			if d > 0.0 and d < 15.0:
				line.append(p)
			elif d > 20.0:
				components.append(line)
				line = []
			if d > 0.0:
				prevPoint = p
				print p, d
		components.append(line)
		components = components[1:]
		
		#draw paths
		figure = plt.figure(figsize=(16, 16), dpi=300)
		axes = figure.add_subplot(111, projection = "3d")
		
		#bounding box for equal axis
		for point in np.diag(100 * np.ones(3)):
			axes.plot([point[0]], [point[1]], [point[2]], 'w')
		
		axes.plot([0, 0, 40, 40, 80, 80, 120, 120], [40, 80, 80, 40, 40, 80, 80, 40], [76, 76, 76, 76, 76, 76, 76, 76], "r-", linewidth=2)
		
		for line in components:
			if len(line) > 1:
				line = np.array(line)
				axes.plot(line[:, 0], line[:, 1], line[:, 2], "g-", linewidth=2)
		plt.xlim([-20, 140])
		plt.ylim([0, 100])
		#plt.zlim([0, 100])
		plt.savefig(str(use) + ".png", bbox_inches='tight')
		#plt.show()
			#print "done", use
			#for i in range(len(components)):
			#	fullComponents[i].extend(components[i])
	exit()
	"""components = fullComponents
	for c in components:
		print len(c)
	pickle.dump(components, open("points_2.pkl", "wb"))
	exit()
	
	components = pickle.load(open("points_2.pkl", "rb"))
	#for i in range(len(components) - 1):
	#	components[i+1] = components[i+1][:80]
	
	for c in components:
		print len(c)"""
	
	#draw paths
	figure = plt.figure()
	axes = figure.add_subplot(111, projection = "3d")
	
	#bounding box for equal axis
	for point in np.diag(100 * np.ones(3)):
		axes.plot([point[0]], [point[1]], [point[2]], 'w')
	
	for line in components:
		if len(line) > 1:
			line = np.array(line)
			axes.plot(line[:, 0], line[:, 1], line[:, 2], "g-", linewidth=3)
	plt.show()