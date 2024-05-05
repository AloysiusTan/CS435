clc, clear, close all
%% 1. Setup
% Define the filenames of the two images
filenames = {'image1.jpg', 'image2.jpg'};

currentDir = fileparts(which('HW4.m'));
resultsDir = fullfile(currentDir, 'results');
imagesDir = fullfile(currentDir, 'images');

% Check if the 'results' directory exists, create it if not
if ~exist(resultsDir, 'dir')
    mkdir(resultsDir);
end

% Define the Gaussian filter to use for both images
gaussian = fspecial('gaussian', [3 3], 1);

for idx = 1:length(filenames)
    filename = filenames{idx};
    % Read the image
    im = imread(fullfile(imagesDir, filename));
    
    %% 2. Energy Function
    % Convert to grayscale
    grayscale_im = rgb2gray(im);

    % Smooth grayscale image
    smooth_grayscale_im = conv2(grayscale_im, gaussian, 'same');

    E = calculate_energy(smooth_grayscale_im);

    energy_im = uint8(E);
    % Display the energy image
    figure('Name', sprintf('%s - Energy Function', filename));
    
    imshow(energy_im);

    % Save the energy image figure
    saveas(gcf, fullfile(resultsDir, sprintf('%s_energy_function.png', filename)));
    %% 3. Optimal Seam
    M = calculate_seam(E);
    optimal_seam = find_seam(M);
    im_with_seam = highlight_seam(im, optimal_seam);

    % Display the result
    figure('Name', sprintf('%s - Optimal Seam', filename));
    imshow(im_with_seam); 
    % Save the figure with the optimal seam
    saveas(gcf, fullfile(resultsDir, sprintf('%s_optimal_seam.png', filename)));

    %% 4. Remove a Seam
    original_width = size(im, 2);
    fprintf('Original width of %s: %d pixels\n', filename, original_width);

    im_without_seam = delete_seam(im, optimal_seam);

    new_width = size(im_without_seam, 2);
    fprintf('New width of %s after removing seam: %d pixels\n', filename, new_width);

    % Check if the width is reduced by one pixel
    if original_width - new_width == 1
        fprintf('Seam successfully removed from %s. Width reduced by 1 pixel.\n', filename);
    else
        fprintf('Error in seam removal: Width change is not as expected for %s.\n', filename);
    end

    % Display the result
    figure('Name', sprintf('%s - Seam Removed', filename));
    imshow(uint8(im_without_seam)); 
    % Save the figure with the optimal seam
    saveas(gcf, fullfile(resultsDir, sprintf('%s_seam_removed.png', filename)));

    %% 5. Remove all the Seams
    % Reusing the functions from earlier sections

    v = VideoWriter(sprintf('results/%s_seam_carving.mp4', filename), 'MPEG-4');
    v.FrameRate = 10; 
    open(v);
    [original_h, original_w, ~] = size(im);
    
    for cur_width = original_w:-1:1
        grayscale_im = rgb2gray(im);
        smooth_grayscale_im = conv2(grayscale_im, gaussian, 'same');
    
        E = calculate_energy(smooth_grayscale_im);
        M = calculate_seam(E);
        optimal_seam = find_seam(M);
        im_with_seam = highlight_seam(im, optimal_seam);
    
        % Ensure frame size matches original image size
        if cur_width > 1
            frame = generate_frame(original_h, original_w, im_with_seam);
            writeVideo(v, frame);
        else
            % Handle the last frame where the image width is 1
            frame = zeros(original_h, original_w, 3, 'like', im);  % Creating a black frame
            writeVideo(v, frame);
        end
    
        if cur_width > 1
            im = delete_seam(im, optimal_seam);
        end
        fprintf("[Seam Carving]: %d of %d frames generated!\n", original_w - cur_width + 1, original_w);
    end
    close(v);
    fprintf('Seam Carving Video creation for %s completed.\n', filename);
end

%% Helper Function
function E = calculate_energy(smooth_grayscale_im)
    % Calculate the energy of an image using the gradient magnitude.
    % smooth_grayscale_im: A pre-smoothed grayscale image.

    % Calculate the gradients in the x and y directions using built-in function
    [Gx, Gy] = imgradientxy(smooth_grayscale_im, 'sobel');

    % Compute the energy function as the sum of the absolute values of the gradients
    E = abs(Gx) + abs(Gy);
end


function M = calculate_seam(E)
    % (From lecture) Calculates the cumulative energy map (M) for vertical seams using DP
    % E is the energy map of the image, with each element representing the energy at that pixel.
    
    [rows, cols] = size(E);  % Get the dimensions of the energy map.
    M = zeros(rows, cols);   % Initialize the cumulative energy map with zeros.

    % Copy the top row of the energy map to the top row of M since there are no predecessors.
    M(1, :) = E(1, :);

    % Iterate over the rest of the rows to compute the cumulative energy map.
    for i = 1:rows
        for j = 1:cols
            % Base case - Top most row
            if i == 1
                M(1, j) = E(1, j);
                continue 
            end

            % Determine the values on the row above current row
            if j-1 < 1
                topLeft = inf;
            else
                topLeft = M(i-1, j-1);
            end

            if i-1 < 1
                topMiddle = inf;
            else
                topMiddle = M(i-1, j);
            end
            
            if j+1 > cols
                topRight = inf;
            else
                topRight = M(i-1, j+1);
            end

            % Take the minimum value of the 3 pixels above the current pixel
            value = min([topLeft topMiddle, topRight]);
            M(i, j) = E(i, j) + value;
        end
    end
end

function seam = find_seam(M)
    % Identifies the optimal vertical seam in the image using the cumulative energy map M.
    % This function backtracks from the bottom to the top of the map to find the path of minimum energy.
    
    [rows, cols] = size(M);
    % Initialize matrix of 0s. Replace 0s with 1s to indicate seam path.
    seam = zeros(rows, cols);

    % Loop backwards from M, finding least value in each row
    for i = rows:-1:2
        % Handle starting value by finding minimum value in last row of M
        if i == rows
            lastRow = M(rows, :);
            [~, j] = min(lastRow);
            seam(rows, j) = 1;
        end
        
        % Determine the 3 values above the current value
        if j-1 < 1
            topLeft = inf;
        else
            topLeft = M(i-1, j-1);
        end

        if i-1 < 1
            topMiddle = inf;
        else
            topMiddle = M(i-1, j);
        end

        if j+1 > cols
            topRight = inf;
        else
            topRight = M(i-1, j+1);
        end

        % Find the minimum value y coordinate
        values = [topLeft topMiddle, topRight];
        col_coordinates = [j-1 j j+1];
        
        [~, index] = min(values);
        j = col_coordinates(index);
        
        % Update optimal path
        seam(i-1, j) = 1;
    end
end

function im_with_seam = highlight_seam(im, seam)
% Highlights the optimal vertical seam path on an image with a red color.
% im is the original RGB image.
% seam is a vector of column indices that denote the path of the seam in the image.

    [rows, cols] = size(seam);
    
    % Alter original pixel value in red if coordinate value in optimal seam is equal to 1.
    for i = 1:rows
        for j= 1:cols
            if(seam(i, j) == 1)
               im(i, j, 1) = 255; % R
               im(i, j, 2) = 0; % G
               im(i, j, 3) = 0; % B
            end
        end
    end
    im_with_seam = im;
end

function new_im = delete_seam(im, seam)
% Delete the seam from the image

    % Retrieve size of current image
    [rows, cols, numChannels] = size(im);
    
    % Initialize new image matrix, removing one column
    new_im = zeros(rows, cols-1, numChannels, 'like', im);

    for i = 1:rows 
        % Retrieve all values for one row in the optimal seam and find the seam coordinate
        seam_row = seam(i,:);
        [~, col] = find(seam_row == 1);

        % Remove the optimal pixel from the image color channel
        r_channel = im(i, :, 1);
        g_channel = im(i, :, 2);
        b_channel = im(i, :, 3);

        r_channel(col) = [];
        g_channel(col) = [];
        b_channel(col) = [];

        % Write the values to the new image matrix
        new_im(i, :, 1) = r_channel;
        new_im(i, :, 2) = g_channel;
        new_im(i, :, 3) = b_channel;
    end
end

function frame = generate_frame(h, w, im)
    % Generate a padded frame of the original image size to render the modified image.

    % Initialize a blank frame of size h x w for all 3 color channels
    frame = zeros(h, w, 3, 'like', im);  
    
    % Retrieve the size of the input image
    [imgHeight, imgWidth, ~] = size(im);

    % Calculate starting indices to center the image in the frame
    startRow = floor((h - imgHeight) / 2) + 1;
    startCol = floor((w - imgWidth) / 2) + 1;
    
    % Place the image into the frame, centered
    frame(startRow:startRow+imgHeight-1, startCol:startCol+imgWidth-1, :) = im;

    % Ensure the output is the same type as the input
    frame = uint8(frame);
end






