import scipy.io as sio
import numpy as np
import pickle

a = pickle.load(open('points_z_4.pkl', 'rb'))
H = []
for m in a:
	M = np.zeros((len(m), 3))
	for i in range(len(m)):
		M[i, :] = m[i]
	H.append(M)
	
#sio.savemat('points_z_2.mat', dict(a = H[0], b = H[1], c = H[2], d = H[3], e = H[4], f = H[5]))
sio.savemat('points_z_4.mat', dict(a = H[1], b = H[2], c = H[3], d = H[4], e = H[5], f = H[6]))