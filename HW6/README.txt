# Author: Aloysius Tan
# Date: 05/15/2024

## Program Features:
The program processes image classification. The steps included are as follows:
    + Classify images using grayscale histograms and Histogram of Oriented Gradients (HOG) features.
        - Grayscale histograms involve creating and comparing histograms for image classification.
        - HOG features involve segmenting the image into cells, calculating gradient directions, and voting in gradient orientation bins to form descriptors.
This section generates multiple outputs including processed images and classification results.

## Entry-point Script Names: 
- HW6.m (for image classification using histogram and HOG features)


## Instructions to Run HW6:
Ensure the 'carData' and 'results' folder are in the same directory as 'HW6.m'. To test on new images, place them in a new folder inside 'carData' folder and update the variable on line 6 and  of 'HW6.m'. Run 'HW6.m' to execute classification and view results in the 'results' folder.

The script will generate and save results in their respective folders within 'results'.
