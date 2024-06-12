clc; clear; close all;
%% Part 0: Setup
currentDir = fileparts(which('FinalProject.m'));
resultsDir = fullfile(currentDir, 'results');
imagesDir = fullfile(currentDir, 'images');

% Check and create results directory if not existing
if ~exist(resultsDir, 'dir')
    mkdir(resultsDir);
end

%% Part 1: Image Prep and Edge Detection

% Load the image
filename = 'input_image1';
img = imread(fullfile(imagesDir, [filename, '.jpg']));
img_resized = imresize(img, [512 NaN]); % Resize while maintaining aspect ratio

% Convert to grayscale
gray_img = rgb2gray(img_resized);

% Apply edge detection (Canny method)
edges = edge(gray_img, 'Canny');

% Display the original and edge-detected images
figure;
subplot(1, 2, 1);
imshow(img_resized);
title('Original Image');

subplot(1, 2, 2);
imshow(edges);
title('Edge Detected Image');
saveas(gcf, fullfile(resultsDir, [filename '_edge.jpg']));

%% Part 2: Manual Hough Transform for Line Detection

[rows, cols] = size(edges);
theta = -90:89;
rho_max = round(sqrt(rows^2 + cols^2));
rho = -rho_max:rho_max;
H = zeros(length(rho), length(theta));

edge_points = find(edges);
[y_coords, x_coords] = ind2sub([rows, cols], edge_points);

for i = 1:length(edge_points)
    x = x_coords(i);
    y = y_coords(i);
    for t = 1:length(theta)
        theta_rad = deg2rad(theta(t));
        r = round(x * cos(theta_rad) + y * sin(theta_rad));
        rho_idx = r + rho_max + 1;
        H(rho_idx, t) = H(rho_idx, t) + 1;
    end
end

% Display the Hough transform result
figure;
imshow(imadjust(rescale(H)), 'XData', theta, 'YData', rho, 'InitialMagnification', 'fit');
xlabel('\theta (degrees)');
ylabel('\rho');
axis on;
axis normal;
colormap(gca, hot);
title('Hough Transform');
saveas(gcf, fullfile(resultsDir, [filename '_hough_transform.jpg']));

%% Part 3: Relevant Line Identification

numPeaks = 10;
threshold = ceil(0.58 * max(H(:)));
peaks = [];

H_size = size(H);
for i = 1:numPeaks
    % Find maximum value in H
    [max_val, idx] = max(H(:));
    if max_val < threshold
        break;
    end
    [r, c] = ind2sub(H_size, idx);
    peaks = [peaks; r, c];
    
    % Suppress this peak
    suppress_radius = 80; % You can adjust this value
    r_min = max(1, r - suppress_radius);
    r_max = min(H_size(1), r + suppress_radius);
    c_min = max(1, c - suppress_radius);
    c_max = min(H_size(2), c + suppress_radius);
    H(r_min:r_max, c_min:c_max) = 0;
end

% Convert peaks to lines
lines = [];
for i = 1:size(peaks, 1)
    rho_idx = peaks(i, 1);
    theta_idx = peaks(i, 2);
    rho_val = rho(rho_idx);
    theta_val = theta(theta_idx);
    lines = [lines; rho_val, theta_val];
end

% Filter Out Duplicate or Similar Lines
angle_threshold = 5;
distance_threshold = 10;

% Helper function to check if two lines are similar
are_similar = @(line1, line2) ...
    (abs(line1(2) - line2(2)) < angle_threshold) && ...
    (abs(line1(1) - line2(1)) < distance_threshold);

% Filter similar lines
filtered_lines = [];
for i = 1:size(lines, 1)
    line = lines(i, :);
    is_similar = false;
    for j = 1:size(filtered_lines, 1)
        if are_similar(line, filtered_lines(j, :))
            is_similar = true;
            break;
        end
    end
    if ~is_similar
        filtered_lines = [filtered_lines; line];
    end
end

% Categorize Lines Based on Orientation
horizontal_lines = [];
vertical_lines = [];

for i = 1:size(filtered_lines, 1)
    line = filtered_lines(i, :);
    if abs(line(2)) < 10 || abs(line(2)) > 170  % Near horizontal
        horizontal_lines = [horizontal_lines; line];
    elseif abs(line(2)) > 80 && abs(line(2)) < 100  % Near vertical
        vertical_lines = [vertical_lines; line];
    end
end

% Validate Horizontal Lines Based on Spacing Consistency
y_spacing_threshold = 10;
validated_horizontal_lines = [];
prev_rho = [];

for i = 1:size(horizontal_lines, 1)
    line = horizontal_lines(i, :);
    rho_val = line(1);
    if isempty(prev_rho) || abs(rho_val - prev_rho) > y_spacing_threshold
        validated_horizontal_lines = [validated_horizontal_lines; line];
        prev_rho = rho_val;
    end
end

% Ensure only top two horizontal and vertical lines are selected
validated_horizontal_lines = sortrows(validated_horizontal_lines, 1);
validated_vertical_lines = sortrows(vertical_lines, 1);

top_horizontal_lines = validated_horizontal_lines(1:min(2, end), :);
top_vertical_lines = validated_vertical_lines(1:min(2, end), :);

% Combine top horizontal and vertical lines
relevant_lines = [top_horizontal_lines; top_vertical_lines];

% Display lines on the edge image
figure;
imshow(edges);
hold on;
for k = 1:size(relevant_lines, 1)
    rho_val = relevant_lines(k, 1);
    theta_val = relevant_lines(k, 2);
    x = 1:cols;
    y = (rho_val - x * cosd(theta_val)) / sind(theta_val);
    plot(x, y, 'LineWidth', 2, 'Color', 'red');
end
title('Detected Lines');
saveas(gcf, fullfile(resultsDir, [filename '_detected_lines.jpg']));

%% Part 4: Line Intersections

% Convert polar to slope-intercept form
intersections = [];
for i = 1:size(relevant_lines, 1)
    for j = i+1:size(relevant_lines, 1)
        slope1 = -cosd(relevant_lines(i, 2)) / sind(relevant_lines(i, 2));
        intercept1 = relevant_lines(i, 1) / sind(relevant_lines(i, 2));
        slope2 = -cosd(relevant_lines(j, 2)) / sind(relevant_lines(j, 2));
        intercept2 = relevant_lines(j, 1) / sind(relevant_lines(j, 2));
        x = (intercept2 - intercept1) / (slope1 - slope2);
        y = slope1 * x + intercept1;
        if isfinite(x) && isfinite(y) && x >= 1 && x <= cols && y >= 1 && y <= rows % Check if intersection is valid and within bounds
            intersections = [intersections; x, y];
        end
    end
end

% Sort intersections to get the four corners in order (top-left, top-right, bottom-right, bottom-left)
mean_intersection = mean(intersections);
deltas = bsxfun(@minus, intersections, mean_intersection);
angles = atan2(deltas(:,2), deltas(:,1));
[~, sort_order] = sort(angles);
sorted_intersections = intersections(sort_order, :);

% Display intersections on the image
figure;
imshow(img_resized);
hold on;
plot(sorted_intersections(:,1), sorted_intersections(:,2), 'ro', 'LineWidth', 2, 'MarkerSize', 6, 'MarkerFaceColor', 'red');
title('Line Intersections');
saveas(gcf, fullfile(resultsDir, [filename '_line_intersections.jpg']));

%% Part 5: Image Rectification (Manual Application)

% Assuming corners are the four points found
source_points = sorted_intersections;

% Order the corners correctly
% Top-left, top-right, bottom-right, bottom-left
ordered_points = zeros(4, 2);
centroid = mean(source_points);
for i = 1:4
    if source_points(i, 1) < centroid(1) && source_points(i, 2) < centroid(2)
        ordered_points(1, :) = source_points(i, :); % Top-left
    elseif source_points(i, 1) > centroid(1) && source_points(i, 2) < centroid(2)
        ordered_points(2, :) = source_points(i, :); % Top-right
    elseif source_points(i, 1) > centroid(1) && source_points(i, 2) > centroid(2)
        ordered_points(3, :) = source_points(i, :); % Bottom-right
    elseif source_points(i, 1) < centroid(1) && source_points(i, 2) > centroid(2)
        ordered_points(4, :) = source_points(i, :); % Bottom-left
    end
end

% Define the dimensions of the blank target image
blank_height = 1100; % 11 inches * 100 (for finer details)
blank_width = 850;   % 8.5 inches * 100 (for finer details)

% Define the four corners of the target image
target_points = [
    0, 0; % Top-left
    blank_width-1, 0; % Top-right
    blank_width-1, blank_height-1; % Bottom-right
    0, blank_height-1; % Bottom-left
];

% Compute the homography matrix
A = [];
for i = 1:4
    x = ordered_points(i, 1);
    y = ordered_points(i, 2);
    xp = target_points(i, 1);
    yp = target_points(i, 2);
    A = [A; 
         -x, -y, -1, 0, 0, 0, x*xp, y*xp, xp;
         0, 0, 0, -x, -y, -1, x*yp, y*yp, yp];
end

[~, ~, V] = svd(A);
H = reshape(V(:, 9), 3, 3)';

% Normalize the homography matrix
H = H / H(3, 3);

% Initialize the blank rectified image
rectified_image = zeros(blank_height, blank_width, size(img_resized, 3), 'uint8');

% Map each pixel in the blank image back to the original image
for x = 1:blank_width
    for y = 1:blank_height
        target_coord = [x; y; 1];
        source_coord = H \ target_coord;
        source_coord = source_coord ./ source_coord(3);
        
        xs = round(source_coord(1));
        ys = round(source_coord(2));
        
        if xs > 0 && xs <= cols && ys > 0 && ys <= rows
            rectified_image(y, x, :) = img_resized(ys, xs, :);
        end
    end
end

% Display the rectified image
figure;
imshow(rectified_image);
title('Rectified Image');
saveas(gcf, fullfile(resultsDir, [filename '_rectified.jpg']));

