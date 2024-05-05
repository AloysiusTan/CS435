clc, clear, close all

%% 1. Data Setup
image_files ={'images/image1.jpg', 'images/image2.jpg'};

% Current directory where the HW2.m script is located
currentDir = fileparts(which('HW2.m'));

% Path to the 'results' subfolder
resultsDir = fullfile(currentDir, 'results');

% Check if the 'results' directory exists, create it if not
if ~exist(resultsDir, 'dir')
    mkdir(resultsDir);
end

% Small and large dimensions for each image
small_sizes = {[74, 132], [74, 114]};
large_sizes = {[296, 530], [296, 458]};

for i = 1:length(image_files)
    % Read the image
    img = imread(image_files{i}); 
    
    % Get the size of the image
    [height, width, depth] = size(img);
    
    % Display the dimensions
    fprintf('Current height: %d pixels\n', height);
    fprintf('Current width: %d pixels\n', width);
end

%% 2. Image Resizing
% Loop over each image file
for i = 1:length(image_files)
    % Read the original image
    original_img = imread(image_files{i});

    % Small and large target dimensions for the current image
    small_height = small_sizes{i}(1);
    small_width = small_sizes{i}(2);
    large_height = large_sizes{i}(1);
    large_width = large_sizes{i}(2);

    % Nearest neighbor resized image
    nn_small_img = nearest_neighbor(original_img, small_height, small_width);
    nn_large_img = nearest_neighbor(original_img, large_height, large_width);

    % Bilinear interpolation resized image
    bi_small_img = bilinear_interpolation(original_img, small_height, small_width);
    bi_large_img = bilinear_interpolation(original_img, large_height, large_width);

    % Save the resized images with appended filenames
    [~, name, ~] = fileparts(image_files{i});

    % Define save path using the 'results' directory
    save_path = fullfile(resultsDir, [name '_small_nearest.jpg']);
    
    % Display and save the nearest neighbor small image
    figure('Name', [name ' Small Nearest Neighbor']);
    imshow(nn_small_img);
    saveas(gcf, save_path, 'jpg');
    
    % Repeat for other images
    save_path = fullfile(resultsDir, [name '_large_nearest.jpg']);
    figure('Name', [name ' Large Nearest Neighbor']);
    imshow(nn_large_img);
    saveas(gcf, save_path, 'jpg');
    
    save_path = fullfile(resultsDir, [name '_small_bilinear.jpg']);
    figure('Name', [name ' Small Bilinear']);
    imshow(bi_small_img);
    saveas(gcf, save_path, 'jpg');

    save_path = fullfile(resultsDir, [name '_large_bilinear.jpg']);
    figure('Name', [name ' Large Bilinear']);
    imshow(bi_large_img);
    saveas(gcf, save_path, 'jpg');
end

%% Helper functions
% Nearest neighbor
function resized_img = nearest_neighbor(input_img, new_height, new_width)
    [h, w, d] = size(input_img);
    resized_img = zeros(new_height, new_width, d, 'like', input_img);

    for row = 1:new_height
        for col = 1:new_width
            % Formula from the Assignment brief
            orig_x = round((col - 1) * (w - 1) / (new_width - 1) + 1);
            orig_y = round((row - 1) * (h - 1) / (new_height - 1) + 1);
            resized_img(row, col, :) = input_img(orig_y, orig_x, :);
        end
    end
end

% Bilinear Interpolation
function resized_img = bilinear_interpolation(input_img, new_height, new_width)
    [h, w, d] = size(input_img);
    resized_img = zeros(new_height, new_width, d, 'like', input_img);

    for row = 1:new_height
        for col = 1:new_width
            % Calculate the position on the original image
            % Formula from the Assignment brief
            orig_x = (col - 1) * (w - 1) / (new_width - 1) + 1;
            orig_y = (row - 1) * (h - 1) / (new_height - 1) + 1;
            
            x1 = floor(orig_x);
            x2 = ceil(orig_x);
            y1 = floor(orig_y);
            y2 = ceil(orig_y);
            
            % Calculate the weights for interpolation
            wa = (x2 - orig_x) * (y2 - orig_y);
            wb = (orig_x - x1) * (y2 - orig_y);
            wc = (x2 - orig_x) * (orig_y - y1);
            wd = (orig_x - x1) * (orig_y - y1);
            
            % Make sure indices are within the image dimensions
            x1 = max(x1, 1);
            x2 = min(x2, w);
            y1 = max(y1, 1);
            y2 = min(y2, h);
            
            % Compute the interpolated pixel value
            for channel = 1:d
                A = double(input_img(y1, x1, channel));
                B = double(input_img(y1, x2, channel));
                C = double(input_img(y2, x1, channel));
                D = double(input_img(y2, x2, channel));
                
                pixel_value = wa*A + wb*B + wc*C + wd*D;
                resized_img(row, col, channel) = pixel_value;
            end
        end
    end
end






