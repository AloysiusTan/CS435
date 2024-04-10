clc, clear, close all

%% 2. Dataset Setup
Im = imread("star.jpg");

% Convert Image to matrix of doubles
Im_double = double(Im);

% Display original Image
figure('Name', 'Original'); imshow(Im);

%% 3. RGB -> Grayscale
% Grayscale conversion using formula and Scalar-matrix multiplication
Im2_grayscale = 0.2989*Im_double(:,:,1) + 0.5870*Im_double(:,:,2) + ...
                0.1140*Im_double(:,:,3);

% Convert to a unsigned integers (uint8) 
Im2_grayscale = uint8(Im2_grayscale);

% Display and save grayscale Image
figure('Name', 'Grayscaled Image'); imshow(Im2_grayscale); 
saveas(gcf(), 'grayscaled.jpg', 'jpg');

%% 4. RGB -> Binary
% Create three binary Images from the grayscaled version using a threshold 
% percentage of 25%, 50%, and 75% of the maxImum intensity (255)
percentages = [0.25, 0.50, 0.75];
for percentage = percentages
    % Initialize matrix of 0s
    Im3_binary = zeros(size(Im2_grayscale));
    
    % Set any pixel value above threshold to 255
    Im3_binary(Im2_grayscale > percentage * 255) = 255;
    
    % Convert to a unsigned integers (uint8) 
    Im3_binary = uint8(Im3_binary);
    
    % Display and save binary Image
    figureTitle = sprintf('Binary Image (Threshold = %.0f%%)', percentage * 100);
    figure('Name', figureTitle); 
    imshow(Im3_binary);
    
    filePath = sprintf('binary_threshold_%.0f.png', percentage * 100);
    saveas(gcf(), filePath, 'png');
end

%% 5. Gamma Correction
% Convert range from 1 to 255 range to 0 to 1
Im4 = double(Im) / 255;

% Define gamma values
gammas = [0.2, 1, 50];

for gamma = gammas
    % Apply gamma correction directly across all channels
    Im4_gamma = Im4 .^ gamma;
    
    % Convert range back to 0 - 255 and to unsigned integers (uint8)
    Im4_gamma_uint8 = uint8(Im4_gamma * 255);
    
    % Display gamma corrected image
    figureName = sprintf('Gamma Correction Image (Gamma = %.1f)', gamma);
    figure('Name', figureName);
    imshow(Im4_gamma_uint8);
    
    % Optionally, save the figure
    filePath = sprintf('gamma_corrected_%.1f.png', gamma);
    saveas(gcf(), filePath, 'png');
end


%% 6. Histograms
% Return 1D array for each original color channel + gray image
flatGray = reshape(Im2_grayscale, 1, numel(Im2_grayscale));
flatR = reshape(Im(:,:,1), 1, numel(Im(:,:,1)));
flatG = reshape(Im(:,:,2), 1, numel(Im(:,:,2)));
flatB = reshape(Im(:,:,3), 1, numel(Im(:,:,3)));

% Generate histograms
generate_histogram(flatGray, "Grayscale")
generate_histogram(flatR, "Red")
generate_histogram(flatG, "Green")
generate_histogram(flatB, "Blue")

%% Helper Functions
% Takes in a 1D array and creates a histogram based on pixel values.
function generate_histogram(flatX, channel)
    % From Lecture 1 Slide 19
    bins = zeros(1,256);
    for val = 0:255
           bins(val+1) = sum(flatX==val);
    end
    bins = bins/sum(bins);
    
    % Display and save histogram
    figure; bar(1:256,bins); 
    titleStr = sprintf('Histogram of the %s Channel', channel);
    title(titleStr);
    xlabel('bins'); 
    ylabel('Frequency');
    filePath = sprintf('histogram_%s.jpg', channel);
    saveas(gcf(), filePath, 'jpg');
end