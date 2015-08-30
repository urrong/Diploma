import numpy as np
import cv2

img = cv2.imread("camera2.jpg")
mat = np.array([[730.779, 0, 363.7627],
				[0, 802.7942, 261.6723],
				[0, 0, 1]]);

coef = np.array([-0.2939, 0.1639, 0, 0])				

dst = cv2.undistort(img, mat, coef)
cv2.imwrite("out.jpg", dst)