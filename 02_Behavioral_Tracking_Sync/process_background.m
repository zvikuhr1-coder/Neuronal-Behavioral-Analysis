function process_background(behav_path)
% PROCESS_BACKGROUND Generate average background frame from video
%
% Syntax:
%   process_background(behav_path)
%
% Description:
%   Creates a background frame by averaging 150 randomly sampled frames from
%   the behavioral video. This background is used for arena definition and
%   visualization purposes. The function automatically detects video format
%   (.avi or .mp4) and saves the background frame along with video dimensions.
%
% Input:
%   behav_path - String specifying the directory containing the behavioral video
%
% Output Files:
%   background_frame.mat - Contains 'background_frame' (uint8 RGB image)
%   vid_dim.mat - Contains 'vidH' and 'vidW' (video height and width in pixels)
%
% Algorithm:
%   1. Randomly samples 150 frames uniformly across video duration
%   2. Computes pixel-wise average across all sampled frames
%   3. Converts to uint8 format and displays result
%
% Example:
%   behav_path = 'D:\AD_6\AD21\1L1R\TEST';
%   process_background(behav_path);
%
% Notes:
%   - If background_frame.mat already exists, function exits without processing
%   - Prefers .avi files over .mp4 if both are present
%   - Displays progress for each color channel during processing
%
% See also: mmfileinfo, VideoReader, imresize

% Change to behavioral data directory
cd(behav_path)

% Exit if background frame already exists
if exist('background_frame.mat', 'file')
    fprintf('Background frame already exists. Skipping...\n');
    return;
end

% Detect video format (prefer .avi over .mp4)
vis_list = dir('*.avi');
if numel(vis_list) == 1
    vids = dir('*.avi');
elseif numel(vis_list) == 0
    vids = dir('*.mp4');
else
    error('Multiple .avi files found. Please ensure only one video file is present.');
end

% Verify video file exists
if isempty(vids)
    error('No video file (.avi or .mp4) found in %s', behav_path);
end

% Get video properties
filename = fullfile(vids.folder, vids.name);
info = mmfileinfo(vids.name);
vidW = info.Video.Width;
vidH = info.Video.Height;

% Initialize video reader
vid = VideoReader(filename);
nframes = vid.NumFrames;

% Generate random frame indices for sampling
N = 150;  % Number of frames to sample
r = 1 + (nframes - 1) .* rand(N, 1);

% Initialize accumulator for background frame (double precision for averaging)
background_frame = zeros(vidH, vidW, 3);

% Process each color channel separately
for k = 1:3
    fprintf('Processing color channel %d of 3...\n', k);
    
    % Accumulate pixel values across all sampled frames
    for i = 1:N
        % Read randomly selected frame
        thisframe = double(read(vid, ceil(r(i))));
        thisframe = imresize(thisframe, [vidH vidW]);
        
        % Add to accumulator (vectorized for efficiency)
        background_frame(:, :, k) = background_frame(:, :, k) + thisframe(:, :, k);
    end
end

% Compute average and convert to uint8
background_frame = background_frame / N;
background_frame = uint8(background_frame);

% Display result
figure('Name', 'Background Frame', 'NumberTitle', 'off');
imshow(background_frame);
title('Average Background Frame');

% Save outputs
cd(behav_path)
save('background_frame', 'background_frame');
save('vid_dim', 'vidH', 'vidW');

fprintf('Background frame created and saved successfully.\n');

end