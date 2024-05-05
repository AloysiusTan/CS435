clc, clear, close all
%% 1. Data Setup
% Load the grayscale image
I = imread('images/circles1.gif');

currentDir = fileparts(which('HW3.m'));
resultsDir = fullfile(currentDir, 'results');

% Check if the 'results' directory exists, create it if not
if ~exist(resultsDir, 'dir')
    mkdir(resultsDir);
end
%% 2. Gaussian Smoothing
% Define different combinations of K and σ
combinations = [
    3, 1;
    5, 1.5;
    7, 2;
    9, 3
];

% Display the original grayscale image
figure; imshow(I);
title('Original Grayscale Image');
save_path = fullfile(resultsDir, 'q2_grayscale.png');
saveas(gcf(), save_path);

% Loop through combinations
for i = 1:size(combinations, 1)
    K = combinations(i, 1); % Kernel size
    sigma = combinations(i, 2); % Gaussian variance
    
    % Compute Gaussian kernel
    kernel = zeros(K, K);
    center = floor(K / 2) + 1;
    for x = 1:K
        for y = 1:K
            kernel(x, y) = exp(-((x - center)^2 + (y - center)^2) / (2 * sigma^2));
        end
    end
    kernel = kernel / sum(kernel(:)); % Normalize kernel
    
    % Convolve the kernel with the image
    smoothed_image = zeros(size(I));
    [rows, cols] = size(I);
    for x = center:rows - center + 1
        for y = center:cols - center + 1
            window = double(I(x - center + 1:x + center - 1, y - center + 1:y + center - 1));
            smoothed_image(x, y) = sum(window(:) .* kernel(:));
        end
    end
    
    % Display the smoothed image
    figure; imshow(smoothed_image, []);
    title(sprintf('Smoothed Image (K = %d, σ = %.1f)', K, sigma));
    save_path = fullfile(resultsDir, sprintf('guassian_K%d_sigma%.1f.png', K, sigma));
    saveas(gcf(), save_path, 'png');
end

%% 3. Gradients
smoothed_image = imread('images/circles1.gif');

% Define Sobel kernels for gradient computation
sobel_x = [-1, 0, 1; -2, 0, 2; -1, 0, 1];
sobel_y = [-1, -2, -1; 0, 0, 0; 1, 2, 1];

% Compute gradients using convolution
gradient_x = conv2(double(smoothed_image), sobel_x, 'same');
gradient_y = conv2(double(smoothed_image), sobel_y, 'same');

% Compute magnitude of combined gradients
gradient_magnitude = sqrt(gradient_x.^2 + gradient_y.^2);

% Display the gradient images
figure; imshow(abs(gradient_x), []);
title('Absolute Change in X');
save_path = fullfile(resultsDir, 'q3_x.png');
saveas(gcf(), save_path);

figure; imshow(abs(gradient_y), []);
title('Absolute Change in Y');
save_path = fullfile(resultsDir, 'q3_y.png');
saveas(gcf(), save_path);

figure; imshow(gradient_magnitude, []);
title('Gradient Magnitude');
save_path = fullfile(resultsDir, 'q3_magnitude.png');
saveas(gcf(), save_path);

%% 4. Non Maximum Suppression
% Compute the magnitude and angle of the gradient for each pixel
gradient_angle = atan2(gradient_y, gradient_x); % Compute gradient angle

% Initialize the output image for non-maximum suppression
nms_image = zeros(size(gradient_magnitude));

% Loop through each pixel to perform non-maximum suppression
for i = 2:size(gradient_magnitude, 1) - 1
    for j = 2:size(gradient_magnitude, 2) - 1
        angle = gradient_angle(i, j);
        mag = gradient_magnitude(i, j);
        
        % Compare magnitude of the gradient with neighbors based on angle
        if (angle < -7*pi/8 || angle >= 7*pi/8 || (-pi/8 <= angle && angle < pi/8))
            % Check left and right neighbors
            if (mag >= gradient_magnitude(i, j - 1) && mag >= gradient_magnitude(i, j + 1))
                nms_image(i, j) = mag;
            end
        elseif (-5*pi/8 <= angle && angle < -3*pi/8) || (3*pi/8 <= angle && angle < 5*pi/8)
            % Check up and down neighbors
            if (mag >= gradient_magnitude(i - 1, j) && mag >= gradient_magnitude(i + 1, j))
                nms_image(i, j) = mag;
            end
        elseif (-3*pi/8 <= angle && angle < -pi/8) || (5*pi/8 <= angle && angle < 7*pi/8)
            % Check up-right and down-left neighbors
            if (mag >= gradient_magnitude(i - 1, j + 1) && mag >= gradient_magnitude(i + 1, j - 1))
                nms_image(i, j) = mag;
            end
        elseif (-7*pi/8 <= angle && angle < -5*pi/8) || (pi/8 <= angle && angle < 3*pi/8)
            % Check up-left and down-right neighbors
            if (mag >= gradient_magnitude(i - 1, j - 1) && mag >= gradient_magnitude(i + 1, j + 1))
                nms_image(i, j) = mag;
            end
        end
    end
end

% Display the image after non-maximum suppression
figure; imshow(nms_image, []);
title('Gradient Magnitude after Non-Maximum Suppression');
save_path = fullfile(resultsDir, 'non_maximum_suppresion.png');
saveas(gcf(), save_path);

%% 5. Hystersis
img = imread('images/circles1.gif');
% Apply Gaussian smoothing
smoothed_img = imgaussfilt(img, 1); % You can adjust the standard deviation (1 in this case)

% Calculate gradients
[Gx, Gy] = gradient(double(smoothed_img));
grad_mag = sqrt(Gx.^2 + Gy.^2);

% Define thresholds
low_threshold = 0.1 * max(grad_mag(:));
high_threshold = 0.3 * max(grad_mag(:));

% Hysteresis thresholding
edge_img = zeros(size(img));
for i = 1:size(img, 1)
    for j = 1:size(img, 2)
        if grad_mag(i, j) > high_threshold
            edge_img(i, j) = 1;
        elseif grad_mag(i, j) > low_threshold
            % Check 8 neighbors
            for m = -1:1
                for n = -1:1
                    if i+m >= 1 && i+m <= size(img, 1) && j+n >= 1 && j+n <= size(img, 2)
                        if grad_mag(i+m, j+n) > high_threshold
                            edge_img(i, j) = 1;
                            break;
                        end
                    end
                end
                if edge_img(i, j) == 1
                    break;
                end
            end
        end
    end
end

% Display the result
figure; imshow(edge_img);
title('Hystersis Image');
save_path = fullfile(resultsDir, 'hystersis.png');
saveas(gcf(), save_path);

%% 6. Canny Edge Detector
% Load another image
original_image = imread('images/image.jfif');

% Display the original image
figure; imshow(original_image);
title('Original Image');
save_path = fullfile(resultsDir, 'q6_original.png');
saveas(gcf(), save_path);

% Convert the image to grayscale
gray_image = rgb2gray(original_image);
figure; imshow(gray_image);
title('Grayscale Image');
save_path = fullfile(resultsDir, 'q6_grayscale.png');
saveas(gcf(), save_path);

% Apply Gaussian smoothing
smoothed_image = imgaussfilt(gray_image, 3); % Assuming sigma = 3

% Plot and save Smoothed Image
figure; imshow(smoothed_image);
title('Smoothed Image');
save_path = fullfile(resultsDir, 'q6_smoothed.png');
saveas(gcf(), save_path);

% Compute gradients and gradient magnitude
[gradient_x, gradient_y] = gradient(double(smoothed_image));
gradient_magnitude = sqrt(gradient_x.^2 + gradient_y.^2);

% Plot and save Gradient Magnitude
figure; imshow(gradient_magnitude, []);
title('Gradient Magnitude');
save_path = fullfile(resultsDir, 'q6_magnitude.png');
saveas(gcf(), save_path);

% Perform non-maximum suppression
nms_image = zeros(size(gradient_magnitude));
for i = 2:size(gradient_magnitude, 1) - 1
    for j = 2:size(gradient_magnitude, 2) - 1
        angle = atan2(gradient_y(i, j), gradient_x(i, j));
        mag = gradient_magnitude(i, j);
        if (angle < -7*pi/8 || angle >= 7*pi/8 || (-pi/8 <= angle && angle < pi/8))
            if (mag >= gradient_magnitude(i, j - 1) && mag >= gradient_magnitude(i, j + 1))
                nms_image(i, j) = mag;
            end
        elseif (-5*pi/8 <= angle && angle < -3*pi/8) || (3*pi/8 <= angle && angle < 5*pi/8)
            if (mag >= gradient_magnitude(i - 1, j) && mag >= gradient_magnitude(i + 1, j))
                nms_image(i, j) = mag;
            end
        elseif (-3*pi/8 <= angle && angle < -pi/8) || (5*pi/8 <= angle && angle < 7*pi/8)
            if (mag >= gradient_magnitude(i - 1, j + 1) && mag >= gradient_magnitude(i + 1, j - 1))
                nms_image(i, j) = mag;
            end
        elseif (-7*pi/8 <= angle && angle < -5*pi/8) || (pi/8 <= angle && angle < 3*pi/8)
            if (mag >= gradient_magnitude(i - 1, j - 1) && mag >= gradient_magnitude(i + 1, j + 1))
                nms_image(i, j) = mag;
            end
        end
    end
end

% Plot and save Gradient Magniture after Non-Maximum Suppression
figure; imshow(nms_image, []);
title('Gradient Magnitude after Non-Maximum Suppression');
save_path = fullfile(resultsDir, 'q6_nms_magnitude.png');
saveas(gcf(), save_path);

% Double thresholding
low_threshold = 0.1 * max(nms_image(:));
high_threshold = 0.3 * max(nms_image(:));
edge_map = zeros(size(nms_image));
edge_map(nms_image >= high_threshold) = 1;
edge_map(nms_image >= low_threshold & nms_image < high_threshold) = 0.5; % Weak edges

figure; imshow(edge_map);
title('Edge Map after Double Thresholding');
save_path = fullfile(resultsDir, 'q6_edge_map.png');
saveas(gcf(), save_path);

% Edge tracking by hysteresis
edge_map = edge(edge_map, 'Canny');
figure; imshow(edge_map);
title('Final Edge Map');
save_path = fullfile(resultsDir, 'q6_final_edge.png');
saveas(gcf(), save_path);




