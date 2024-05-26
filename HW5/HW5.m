clc, clear, close all
%% 1. Setup
currentDir = fileparts(which('HW5.m'));
resultsDir = fullfile(currentDir, 'results');
imagesDir = fullfile(currentDir, 'images');

%% 2. Generate Fake Data
% Define the image size
imageSize = [400 400];

% Initialize the binary image
binaryImage = zeros(imageSize);

% Parameters for the line
m = 1; % slope
b = -100; % y-intercept

% Generate the line
for x = 1:imageSize(2)
    y = round(m*x + b);
    if y >= 1 && y <= imageSize(1)
        binaryImage(y, x) = 1;
    end
end

% Parameters for the circle
x0 = 100;
y0 = 200;
r = 50;

% Generate the circle
theta = linspace(0, 2*pi, 360);
xCircle = r * cos(theta) + x0;
yCircle = r * sin(theta) + y0;
indices = round([yCircle' xCircle']);
indices = indices(all(indices > 0 & indices <= imageSize(1), 2), :);
for i = 1:size(indices,1)
    binaryImage(indices(i,1), indices(i,2)) = 1;
end

% Display the binary image
imshow(binaryImage);
title('Generated Binary Image with Line and Circle');
saveas(gcf, fullfile(resultsDir, 'fake_data.png'));

%% 3. Hough Transform for a Line 

% Image dimensions and diagonal length calculation
imageWidth = imageSize(2);
imageHeight = imageSize(1);
diagonalLength = ceil(sqrt(imageWidth^2 + imageHeight^2));

% Theta and rho ranges
thetaRange = 0:1:359; % Theta from 0 to 359 degrees
rhoRange = 0:1:diagonalLength; % Rho from 0 to the image diagonal

% Initialize the Hough Transform accumulator
houghSpace = zeros(length(rhoRange), length(thetaRange));

% Find edge (white) pixel indices
[yIndices, xIndices] = find(binaryImage);

% Perform the Hough Transform
for pixel = 1:length(xIndices)
    x = xIndices(pixel);
    y = yIndices(pixel);
    for theta = thetaRange
        % Compute rho for each theta
        rho = round(x * cosd(theta) + y * sind(theta));
        if rho >= 0 && rho <= diagonalLength
            % Increment the accumulator
            houghSpace(rho + 1, theta + 1) = houghSpace(rho + 1, theta + 1) + 1;
        end
    end
end

% Display the Hough Transform
figure;
% imagesc(thetaRange, rhoRange, houghSpace);
% title('Hough Transform for a Line');
% xlabel('\theta (degrees)');
% ylabel('\rho (pixels)');
% colormap(gca, hot);
houghTransformImage = mat2gray(houghSpace);
imshow(houghTransformImage, 'XData', thetaRange, 'YData', rhoRange, 'InitialMagnification', 'fit');
title('Hough Transform for a Line');
xlabel('\theta (degrees)');
ylabel('\rho (pixels)');
axis on, axis normal;
colormap(gca, hot);
colorbar;

% Save the Hough Transform image
saveas(gcf(), fullfile(resultsDir, 'hough_transform_line_polar.png'));

% Find the maximum in the Hough Space
[~, maxIndex] = max(houghSpace(:));
[rhoIndex, thetaIndex] = ind2sub(size(houghSpace), maxIndex);
maxRho = rhoRange(rhoIndex);
maxTheta = thetaRange(thetaIndex);

% Convert (theta, rho) to (m, b) using negative reciprocal (since theta is measured from the x-axis)
m = -cotd(maxTheta);
b = maxRho / sind(maxTheta);

% Output the max values and corresponding line parameters
fprintf('Max (theta, rho): (%d, %d)\n', maxTheta, maxRho);
fprintf('Corresponding (m, b): (%.2f, %.2f)\n', m, b);

% Display the detected line on the binary image
figure;
imshow(binaryImage);
hold on;
if isinf(m)
    xLine = [b b];
    yLine = [1 imageHeight];
else
    xLine = [1 imageWidth];
    yLine = m * xLine + b;
end
plot(xLine, yLine, 'r-', 'LineWidth', 2);
title('Detected Line on Binary Image');

%% 4. Hough Transform for a Circle

% Define the known radius
radius = 50; 

% Define search space for the center within the bounds of the image
x0Range = 1:imageSize(1);
y0Range = 1:imageSize(2);

% Initialize the Hough space for circle centers
houghSpaceCircle = zeros(length(y0Range), length(x0Range));

% Iterate through each white pixel in the binary image
for pixel = 1:length(xIndices)
    x = xIndices(pixel);
    y = yIndices(pixel);

    for theta = 0:359
        a = round(x - radius * cosd(theta));
        b = round(y - radius * sind(theta));
        if a >= 1 && a <= imageSize(2) && b >= 1 && b <= imageSize(1)
            houghSpaceCircle(b, a) = houghSpaceCircle(b, a) + 1;
        end
    end
end

% Find the peak in the Hough accumulator
[maxVal, maxIdx] = max(houghSpaceCircle(:));
[yIdx, xIdx] = ind2sub(size(houghSpaceCircle), maxIdx);
bestX0 = xIdx;
bestY0 = yIdx;

% Display the detected circle on the binary image
figure;
imshow(binaryImage);
hold on;
theta = linspace(0, 2*pi, 360);
xCircle = radius * cos(theta) + bestX0;
yCircle = radius * sin(theta) + bestY0;
plot(xCircle, yCircle, 'r-', 'LineWidth', 2);
title('Detected Circle on Binary Image');

% Display the Hough Transform for the circle
figure;
imagesc(houghSpaceCircle);
title(['Hough Transform for Circle (radius = ', num2str(radius), ')']);
xlabel('x-coordinate');
ylabel('y-coordinate');
colormap(gca, hot);

% Output the detected circle parameters
fprintf('Detected Circle Parameters (x0, y0, r): (%d, %d, %d)\n', bestX0, bestY0, radius);
% Save the Hough Transform image
saveas(gcf, fullfile(resultsDir, 'hough_transform_circle.png'));
%% 5. Apply to a Real Image

% Load the grayscale image
filename = 'circles1.gif';
realImage = imread(fullfile(imagesDir, filename));

% Display the original image
figure('Position', [100, 100, 1200, 400]);
subplot(1, 3, 1); 
imshow(realImage);
title('Original Image');

% Apply edge detection
binaryEdgeImage = edge(realImage, 'Canny');
subplot(1, 3, 2);
imshow(binaryEdgeImage);
title('Detected Edges');

% Define the radius range expected for the largest coin
radiusMin = 75;  
radiusMax = 120; 

% Create the Hough space 
houghSpace = zeros(size(realImage, 1), size(realImage, 2), radiusMax-radiusMin+1);

% Perform Hough Transform
for x = 1:size(binaryEdgeImage, 2)
    for y = 1:size(binaryEdgeImage, 1)
        if binaryEdgeImage(y, x)  % Check if there is an edge
            for radius = radiusMin:radiusMax
                for angle = 0:360
                    t = deg2rad(angle);
                    a = round(x - radius * cos(t));
                    b = round(y - radius * sin(t));
                    if a > 0 && a <= size(realImage, 2) && b > 0 && b <= size(realImage, 1)
                        houghSpace(b, a, radius-radiusMin+1) = houghSpace(b, a, radius-radiusMin+1) + 1;
                    end
                end
            end
        end
    end
end

% Finding the maximum in the Hough space to identify the most dominant circle
[maxValue, idx] = max(houghSpace(:));
[yCenter, xCenter, rIdx] = ind2sub(size(houghSpace), idx);
radius = rIdx + radiusMin - 1;

% Display the result on the original image
subplot(1, 3, 3);
imshow(realImage);
viscircles([xCenter, yCenter], radius, 'EdgeColor', 'r');
title('Detected Circle');

% Save the figure
saveas(gcf, fullfile(resultsDir, 'circles1_coin.png'));

% Print the parameters used for detection
fprintf('Parameters used:\nRadius Min: %d\nRadius Max: %d\nDetected Circle Center: (%d, %d)\nRadius: %d\n', ...
    radiusMin, radiusMax, xCenter, yCenter, radius);


