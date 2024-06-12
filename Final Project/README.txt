# Author: Aloysius Tan
# Date: 06/04/2024

## Program Features:
The program processes an image of a piece of paper using several computational photography techniques to develop a "scanner app". It includes the following steps:
	+ Image Preparation and Edge Detection: Resize the image to a height of 512 pixels while maintaining the aspect ratio and apply edge detection to extract the edges.
	+ Hough Transform for Line Detection: Perform a Hough Transform to detect lines in the edge-detected image and display the result as an image.
	+ Relevant Line Identification: Identify the local maxima in the Hough Transform space and select the relevant lines that form the four edges of the paper. This involves setting a threshold, finding local maxima over a fixed window size, and applying constraints based on the problem.
	+ Line Intersections: Compute the intersections of the selected lines to determine the four corners of the paper.
	+ Image Rectification: Using the four corners, compute the homography matrix to transform the image and rectify the paper to a standard 8.5 × 11 letter size.
	+ Generalization: Test the implementation on another example image to ensure it works without any code changes.

This section will generate 5 images for each input image.

## Entry-point Script Name: Project.m

## Instructions to Run:
Ensure the 'images' and 'results' folder is in the same directory as 'Project.m'. You can then open 'Project.m' 
and run all. All results will be overwritten and saved in a sub-folder named after the image in the 
'results' folder. Once all that is done, click run to execute the code. 

If you wish to test on a new image, put that image in the 'images' folder and change the variable name on line 13 to the name of the image.

Additional Features:
It provides flexibility in adjusting parameters such as thresholding and window size.

