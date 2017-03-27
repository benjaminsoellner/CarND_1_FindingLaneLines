# Self Driving Car Engineer Project 1 - Finding Lane Lines on the Road
## Benjamin Söllner, 27 Mar 2017

---

![Fun Project Header Image](project_carnd_1_finding_lane_lines_400.png)

---

The goals / steps of this project are the following:
* Make a pipeline that finds lane lines on the road: realized with a [python notebook](P1.ipynb).
* Reflect on your work in a written report: provided in this document.

---

### Reflection

###1. Describe your pipeline. As part of the description, explain how you modified the draw_lines() function.

My pipeline consists of the following steps:
* ``grayscale(...)``: Grayscaling the image in order to find gradients better
* ``gaussian_blur(...)``: Blurring the image in order to ignore gradients caused by noise in the image (kernel size = 3)
* ``canny(...)``: Canny edge detection (low threshold = 150, high threshold = 180 - higher numbers than used in the lecture practice in order to avoid falsely deteced lines)
* ``region_of_interest(...)``: Masking a trapezoid polygon in the image which roughly covers the road straight ahead. Vertically, it stretches from the lower edge of the image up to 60% height of the image (the "horizon"). Horizontally, on its lower edge, it reaches across the width 10-90% of width and on its higher edge 45-55% of width.
* ``hough_lines(...)``: Facilitates 3 different functions:
  1. performs Hough Transformation on the highlighted area (distance resolution *rho* = 2, angular resolution *theta* = *pi*/180 = 1deg, minimum number of votes = 40, minimum line length = 20, maximum line gap = 20)
  2. ``draw_lines(...)``: averages all the lines found to two separate lines -- left and right -- using the following algorithm:
    * separates the lines in two separate "buckets" -- left and right -- according to the slope *m* for lines described as *y=mx+n* (decision point whether *m* is above or below 0)
    * filter for lines with *1/8\*pi < arctan(m) < 3/8*pi* (only consider lines that have a slope between 22.5deg and 67.5deg rising or falling)
    * discard "rising" lines that are on the right or "falling" lines that are on the left side of the image
    * sample all the remaining lines with one sampling point per x-value -- this yields a point cloud in 2D space for all filtered right lines and all filtered left lines
    * for each of the two point clouds, do a linear regression (``np.polyfit(...)``)
    * for each of the two resulting regression lines, calculate the corresponding line segment with a y start value on the bottom edge of the image and a y end value at a predefined vertical line which corresponds to the imagined horizon (also used in ``region_of_interest(...)`` and set to 60% of image height)
  3. afterwards, draws those line segments on the screen in bright red
* ``weighted_img(...)``: Combines the line segment image and the original image into one image by overlaying using alpha blending.

The changes to ``draw_lines(...)`` are described above in step (2.). While previously a simple iteration was performed through all the line segments returned by the Hough Transformation (with drawing each of them), now, a more sophisticated algorithm is used that just returns 2 line segments finally.

###2. Identify potential shortcomings with your current pipeline

The current pipeline fails on the "challenge video" which features the following tricky image properties during which this lane line detection algorithm does not work:

* bright weather conditions yielding to:
  * big change in contrast on the road and unstable canny edge detection threshold
  * overexposed brightness on the road leading to low contrast and low performance on edge detection
  * high-contrast shadows cast to the ground that have edges in similar angles like lane lines would
* large turns:
  * therefore only short distance from bottom edge along which a line can be interpolated as a linear lane line
* lane-line like lines in the image:
  * flush lines in the image that look like lane lines due to high contrast but are not (like highway barriers, walls on the side of the road etc.)

Also, this lane-line algorithm will only identify simple lane lines, but not merging or crossing lane lines for more complex traffic patterns. Similarly, the lane-line algorithm will fail if we cross a lane line during a lane switching or overtaking maneuver.

###3. Suggest possible improvements to your pipeline

Above listed shortcomings could be improved by the following changes to the algorithm:

1. while taking the gradient in the image with ``canny(...)`` normalizing it by the contrast of the surrounding image
2. during the averaging process, only taking line segments into account that have similar line segments in parallel to them (essentially making sure that both inner and outer edge of a lane line are found, therefore excluding shadow regions)
3. with point (2.), taking into account that the outer segment transitions from a "road color" to a "lane line color" and the inner edge vice-versa.
4. binning the lane lines with respect to slope and only considering the lane lines with steepest slope (therefore eliminating lines which are produced from "lane-line like objects" like walls etc. which are usually further away from lane lines and thus have shallower flush lines)
5. for turns, do not use linear regression but rather a higher order polynomial or bezier-like curves instead
