clc; clear; close all;
%% 1a. Setup for Grayscale Histograms
% Define directories
currentDir = fileparts(which('HW6.m'));
resultsDir = fullfile(currentDir, 'results', 'knn_histograms');
imagesDir = fullfile(currentDir, 'CarData', 'TrainImages');

% Check and create results directory if not existing
if ~exist(resultsDir, 'dir')
    mkdir(resultsDir);
end

% List all .pgm files in the TrainImages directory
files = dir(fullfile(imagesDir, '*.pgm'));

% Initialize matrices for features, labels, and filenames
X = [];
Y = [];
N = {};

% Read each image, generate a grayscale histogram and assign labels
for f = files'
    if ~f.isdir
        im = imread(fullfile(imagesDir, f.name));
        X(end+1, :) = generate_features(im);  % Generate histogram
        Y(end+1, 1) = ~strcmp(f.name(1:3), 'neg');  % 1 = car, 0 = not car
        N = [N; f.name];  % Collect filenames
    end
end

% Shuffle and divide data into training and validation subsets
rng(0);  % Seed for reproducibility
inds = randperm(size(X, 1));
num = floor(size(X, 1) / 3);
X = X(inds, :);
Y = Y(inds, :);
N = N(inds);
Xtrain = X(1:2*num, :);
Ytrain = Y(1:2*num, :);
Xvalid = X(2*num+1:end, :);
Yvalid = Y(2*num+1:end, :);
Nvalid = N(2*num+1:end);

%% 1b. Classification using Grayscale Histograms
correct = 0; % Correct predictions counter
correct_car_idx = [];
correct_not_car_idx = [];
incorrect_car_idx = [];
incorrect_not_car_idx = [];

% Classification using k-NN
for i = 1:size(Xvalid, 1)
    prediction = predict_class(Xvalid(i, :), Xtrain, Ytrain);
    if prediction == Yvalid(i)
        correct = correct + 1;
    end
    % Store indices for correct/incorrect classifications
    [correct_car_idx, correct_not_car_idx, incorrect_car_idx, incorrect_not_car_idx] = ...
        store_results(prediction, Yvalid(i), i, correct_car_idx, correct_not_car_idx, incorrect_car_idx, incorrect_not_car_idx);
end

% Display and save correctly and incorrectly classified images
display_and_save(imagesDir, Nvalid, correct_car_idx, correct_not_car_idx, incorrect_car_idx, incorrect_not_car_idx, resultsDir);

% Calculate and display prediction accuracy
accuracy = correct / numel(Yvalid);
fprintf('Correct Predictions: %d\n', correct);
fprintf('Total Validation Images: %d\n', numel(Yvalid));
fprintf('Accuracy with K-NN using Grayscale Histograms: %.2f%%\n', accuracy * 100);

%% 2a. Setup for Gists (HOG Features)
% Reinitialize matrices for HOG features setup
X = [];
Y = [];
N = [];

% Generate HOG features for each image
for f = files'
    if ~f.isdir
        im = imread(fullfile(imagesDir, f.name));
        X(end+1, :) = generate_hist_hog(im);  % Generate HOG features
        Y(end+1, 1) = ~strcmp(f.name(1:3), 'neg');  % 1 = car, 0 = not car
        N = [N f.name];
    end
end

% Shuffle and divide data into training and validation subsets
rng(0);  % Seed for reproducibility
inds = randperm(size(X, 1));
X = X(inds, :);
Y = Y(inds, :);
N = N(inds);
Xtrain = X(1:2*num, :);
Ytrain = Y(1:2*num, :);
Xvalid = X(2*num+1:end, :);
Yvalid = Y(2*num+1:end, :);

%% 2b. Classification using Gists (HOG Features)
resultsDir = fullfile(currentDir, 'results', 'knn_hog');
if ~exist(resultsDir, 'dir')
    mkdir(resultsDir);
end

correct = 0; % Reset correct predictions counter
correct_car_idx = [];
correct_not_car_idx = [];
incorrect_car_idx = [];
incorrect_not_car_idx = [];

% Classification using k-NN with HOG features
for i = 1:size(Xvalid, 1)
    prediction = predict_class(Xvalid(i, :), Xtrain, Ytrain);
    if prediction == Yvalid(i)
        correct = correct + 1;
    end
    % Store indices for correct/incorrect classifications
    [correct_car_idx, correct_not_car_idx, incorrect_car_idx, incorrect_not_car_idx] = ...
        store_results(prediction, Yvalid(i), i, correct_car_idx, correct_not_car_idx, incorrect_car_idx, incorrect_not_car_idx);
end

% Display and save correctly and incorrectly classified images
display_and_save(imagesDir, Nvalid, correct_car_idx, correct_not_car_idx, incorrect_car_idx, incorrect_not_car_idx, resultsDir);

% Calculate and display prediction accuracy
accuracy = correct / numel(Yvalid);
fprintf('Correct Predictions: %d\n', correct);
fprintf('Total Validation Images: %d\n', numel(Yvalid));
fprintf('Accuracy with K-NN using Gists: %.2f%%\n', accuracy * 100);

%% Store Results function
% updates lists of indices for correctly and incorrectly classified images based on the prediction and the actual label
function [correct_car, correct_not_car, incorrect_car, incorrect_not_car] = store_results(prediction, true_label, idx, correct_car, correct_not_car, incorrect_car, incorrect_not_car)
    if prediction == 1 && true_label == 1
        correct_car = [correct_car, idx];  % Image correctly labeled as a car
    elseif prediction == 0 && true_label == 0
        correct_not_car = [correct_not_car, idx];  % Image correctly labeled as not a car
    elseif prediction == 1 && true_label == 0
        incorrect_car = [incorrect_car, idx];  % Image incorrectly labeled as a car
    elseif prediction == 0 && true_label == 1
        incorrect_not_car = [incorrect_not_car, idx];  % Image incorrectly labeled as not a car
    end
end

%% Display and Save Images Function
% displays and saves the classified images in the specified results directory.
function display_and_save(imagesDir, Nvalid, correct_car_idx, correct_not_car_idx, incorrect_car_idx, incorrect_not_car_idx, resultsDir)
    if ~isempty(correct_car_idx)
        figure('Name', 'Correctly Labeled as a Car');
        im = imread(fullfile(imagesDir, Nvalid{correct_car_idx(1)}));
        imshow(im);
        imwrite(im, fullfile(resultsDir, 'correct_car.png'));
    end

    if ~isempty(correct_not_car_idx)
        figure('Name', 'Correctly Labeled as Not a Car');
        im = imread(fullfile(imagesDir, Nvalid{correct_not_car_idx(1)}));
        imshow(im);
        imwrite(im, fullfile(resultsDir, 'correct_not_car.png'));
    end

    if ~isempty(incorrect_car_idx)
        figure('Name', 'Incorrectly Labeled as a Car');
        im = imread(fullfile(imagesDir, Nvalid{incorrect_car_idx(1)}));
        imshow(im);
        imwrite(im, fullfile(resultsDir, 'incorrect_car.png'));
    end

    if ~isempty(incorrect_not_car_idx)
        figure('Name', 'Incorrectly Labeled as Not a Car');
        im = imread(fullfile(imagesDir, Nvalid{incorrect_not_car_idx(1)}));
        imshow(im);
        imwrite(im, fullfile(resultsDir, 'incorrect_not_car.png'));
    end
end

%% Generate Grayscale Histogram Features function
% generates a normalized histogram of grayscale values
function bins = generate_features(im)
    if size(im, 3) == 3
        im = rgb2gray(im);  % Convert to grayscale if not already
    end

    data = reshape(im, 1, numel(im));  % Flatten the image
    bins = histcounts(data, 256) / numel(data);  % Generate and normalize histogram
end

%% Generate HOG Features function
% divides an image into sub-regions and computes the histogram of oriented gradients in each region
function hog = generate_hist_hog(im)
    hog = [];
    
    % Divide image into 10 non-overlapping 20x20 sub-images
    regions = mat2cell(im,[20 20], [20 20 20 20 20]);
    [x, y] = size(regions);
    
    for i = 1:x
        for j = 1:y
            % Convert cell array to ordinary array
            cur_region = cell2mat(regions(i,j));
            
            % Use derivative kernels from Edges Lecture - Slide 10
            dx = [1/2 0 -1/2;
                  1/2 0 -1/2;
                  1/2 0 -1/2;];

            dy = [1/2 1/2 1/2;
                   0   0   0;
                 -1/2 -1/2 -1/2;];
             
            % Overlay and convolve to obtain directional gradients
            gx = conv2(cur_region, dx, 'same');
            gy = conv2(cur_region, dy, 'same');
            
            % Calculate angle taking the inverse tan of the gradients. 
            % Classification Lecture - Slide 8
            angles = zeros(size(cur_region));
            angles(:,:) = atan2d(gy(:,:), gx(:,:));
            
            % Iterate each angle along flat array
            condensed_angles = reshape(angles, 1, numel(angles));
            
            % 8 angles = 8 bins
            bins = zeros(1,8);
            
            % Possible Orientations: (0°,45°,90°,135°,180°,225°,270°,315°) 
            % Classification Lecture - Slide 10
            for angle = 1:400
                value = condensed_angles(angle);
                if (value >= 0 && value < 45)
                    bins(1) = bins(1) + 1;
                elseif (value >= 45 && value < 90)
                    bins(2) = bins(2) + 1; 
                elseif (value >= 90 && value < 135)
                    bins(3) = bins(3) + 1;
                elseif (value >= 135 && value < 180)
                    bins(4) = bins(4) + 1;
                elseif (value >= 180 && value < 225)
                    bins(5) = bins(5) + 1;
                elseif (value >= 225 && value < 270)
                    bins(6) = bins(6) + 1;
                elseif (value >= 270 && value < 315)
                    bins(7) = bins(7) + 1;
                elseif (value >= 315 && value <= 360)
                    bins(8) = bins(8) + 1;
                end
            end
            bins = bins/8;   
            
            % Concatenate the 10 8-bins to hog array
            hog = [hog bins];
        end
    end
end

%% Predict Class function
function prediction = predict_class(A, B, labels)
    % This function predicts the class by comparing a test feature (A)
    % against all training features (B) using histogram intersection and 
    % votes based on the closest k (k = 5) neighbors.

    % Define the number of neighbors
    k = 5;

    % Initialize the number of training samples and the similarity vector
    num_trains = size(B, 1);
    sims = zeros(num_trains, 1);

    % Calculate histogram intersection similarity for each training sample
    for i = 1:num_trains
        % The histogram intersection for each bin
        sims(i) = sum(min(A, B(i, :)));
    end

    % Find the indices of the k most similar training examples
    [~, I] = maxk(sims, k);

    % Retrieve the labels of these k nearest neighbors
    nearest_labels = labels(I);

    % Perform majority voting to determine the prediction
    % Count the number of votes for 'Car' (1)
    num_votes_for_car = sum(nearest_labels == 1);

    % Predict 'Car' if the majority of the k nearest neighbors are 'Car'
    if num_votes_for_car >= 3
        prediction = 1;  % Car
    else
        prediction = 0;  % Not Car
    end
end


