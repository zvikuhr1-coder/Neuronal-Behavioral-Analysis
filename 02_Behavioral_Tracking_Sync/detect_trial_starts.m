function trials_start = detect_trial_starts(behav_path)
% DETECT_TRIAL_STARTS Identify trial start frames via LED indicator analysis
%
% Syntax:
%   trials_start = detect_trial_starts(behav_path)
%
% Description:
%   Detects trial start times by analyzing LED indicator changes in behavioral
%   video. The function identifies the first trial via change point detection,
%   then calculates subsequent trial starts assuming 5-minute (300 second)
%   intervals. Each detected trial is verified interactively by the user.
%
% Input:
%   behav_path - String specifying directory containing behavioral video,
%                timestamps, and imaging data
%
% Output:
%   trials_start - Nx1 array of frame indices marking the start of each trial
%
% Output Files:
%   trials_start.mat - Located in Matt_files subdirectory, contains:
%                      'trials_start' - Trial start frame indices
%   LED_start_*.mat - First trial LED detection result
%
% Algorithm:
%   1. User draws circular ROI around LED indicator
%   2. Analyzes LED intensity in first 60 seconds of video
%   3. Detects first trial start via linear change point detection
%   4. Calculates subsequent trials by adding 300s to previous trial
%   5. Displays ±20 second windows for user verification of each trial
%   6. Allows manual adjustment if automatic detection is incorrect
%
% Interactive Workflow:
%   - Initial frame display for LED ROI selection
%   - Automatic first trial detection with visualization
%   - Per-trial verification with temporal context
%   - Manual correction option via ginput
%
% Example:
%   behav_path = 'D:\AD_6\AD21\1L1R\TEST';
%   trial_frames = detect_trial_starts(behav_path);
%
% Notes:
%   - Requires timestamps.mat and tc_all_brain_areas_CORRECTED1.mat to exist
%   - Assumes LED intensity increases at trial start
%   - Threshold of 500 for change detection (adjustable in code)
%   - Filters weak changes (within 50 units of max intensity)
%   - If trials_start.mat exists, function exits without reprocessing
%
% See also: extract_video_timestamps, ischange, VideoReader, drawcircle

% Define paths
brain_path = fullfile(behav_path, 'Matt_files');
cd(brain_path);

% Check if trial starts already computed
if ~isempty(dir('trials_start.mat'))
    fprintf('Trial start frames already exist. Loading existing data...\n');
    load('trials_start.mat', 'trials_start');
    return;
end

% Navigate to behavioral data directory
cd(behav_path);

% Locate behavioral video
video_type = '*.avi';
video_info = dir(video_type);

if isempty(video_info)
    error('No .avi video file found in %s', behav_path);
end

video_name = video_info.name;

% Determine number of trials from imaging data
cd(brain_path);
trials = dir(fullfile(behav_path, '*.dcimg'));
num_of_trials = size(trials, 1);

if num_of_trials == 0
    error('No .dcimg imaging files found. Cannot determine number of trials.');
end

fprintf('Detected %d trials from imaging files\n', num_of_trials);

% Load timestamps
timestamps_file = dir('*timestamps*.mat');
if isempty(timestamps_file)
    error('Timestamps file not found. Run extract_video_timestamps first.');
end

load(timestamps_file.name, 'timestamps');
fprintf('Loaded %d timestamps\n', length(timestamps));

% Initialize video reader
v = VideoReader(fullfile(behav_path, video_name));

% Calculate frames to analyze (60 seconds at ~20 fps)
frame_rate = 20;  % Typical rate: 6000 frames / 300 seconds
frames_to_read = min(round(60 * frame_rate), v.NumFrames);

fprintf('Analyzing first %d frames (%.1f seconds) for LED detection\n', ...
    frames_to_read, frames_to_read / frame_rate);

%% LED ROI Selection
fprintf('\n=== LED ROI SELECTION ===\n');
fprintf('Instructions: Draw a circle around the LED indicator\n');

% Display reference frame
frames_ref = read(v, 100);
fig_roi = figure('Name', 'LED ROI Selection', 'Position', [100, 100, 800, 600]);
imagesc(frames_ref(:, :, 1));
colormap gray;
axis image;
title('Draw a circle around the LED indicator', 'FontSize', 12, 'FontWeight', 'bold');
xlabel('X coordinate (pixels)');
ylabel('Y coordinate (pixels)');

% Interactive ROI drawing
roi_obj = drawcircle('Color', 'r', 'LineWidth', 2);
fprintf('Adjust circle size/position as needed. Press any key when ready...\n');
pause;

% Create binary mask from ROI
roi_mask = createMask(roi_obj);
close(fig_roi);

%% Extract LED Intensity Time Series
fprintf('\n=== EXTRACTING LED INTENSITY ===\n');

% Reset video reader
v = VideoReader(fullfile(behav_path, video_name));

% Preallocate intensity array
tc_roi = zeros(frames_to_read, 1);

% Extract mean intensity within ROI for each frame
fprintf('Processing frames: ');
for i = 1:frames_to_read
    if mod(i, 200) == 0
        fprintf('%d/%d ', i, frames_to_read);
    end
    
    frame = readFrame(v);
    frame_gray = double(frame(:, :, 1));  % Use first channel
    
    % Apply ROI mask and compute mean intensity
    roi_pixels = frame_gray(roi_mask);
    tc_roi(i) = mean(roi_pixels, 'omitnan');
end
fprintf('Done\n');

%% First Trial Detection
fprintf('\n=== FIRST TRIAL DETECTION ===\n');

% Detect change points using linear method
TF = ischange(tc_roi, 'linear', 'Threshold', 500);
change_points = find(TF);

if isempty(change_points)
    error('No significant LED changes detected in first 60 seconds. Check LED visibility.');
end

% Filter weak change points (keep only strong changes)
max_intensity = max(tc_roi(change_points));
strong_changes = change_points(tc_roi(change_points) > max_intensity - 50);

if isempty(strong_changes)
    error('No strong LED changes detected after filtering.');
end

% First trial is the first strong change
first_trial_frame = strong_changes(1);
first_trial_time = timestamps(first_trial_frame);

fprintf('First trial detected at frame %d (time = %.2f s)\n', ...
    first_trial_frame, first_trial_time);

%% Calculate All Trial Starts (300s intervals)
fprintf('\n=== CALCULATING TRIAL STARTS ===\n');

% Preallocate trial arrays
trials_start = zeros(num_of_trials, 1);
all_trial_times = zeros(num_of_trials, 1);

trials_start(1) = first_trial_frame;
all_trial_times(1) = first_trial_time;

% Calculate subsequent trials (add 300 seconds)
for tt = 2:num_of_trials
    all_trial_times(tt) = all_trial_times(tt-1) + 300;
    
    % Find closest timestamp to calculated time
    [~, frame_idx] = min(abs(timestamps - all_trial_times(tt)));
    trials_start(tt) = frame_idx;
    
    fprintf('Trial %d: Frame %d (time = %.2f s)\n', ...
        tt, trials_start(tt), all_trial_times(tt));
end

%% Visualize First Trial Detection
fig_first = figure('Name', 'First Trial Detection', 'Position', [100, 500, 1000, 400]);
plot(timestamps(1:frames_to_read), tc_roi, 'b-', 'LineWidth', 1.5);
hold on;
scatter(timestamps(first_trial_frame), tc_roi(first_trial_frame), 150, 'r', 'filled', ...
    'MarkerEdgeColor', 'k', 'LineWidth', 1.5);
grid on;
xlabel('Time (seconds)', 'FontSize', 11);
ylabel('LED Intensity (a.u.)', 'FontSize', 11);
title('First Trial Detection', 'FontSize', 12, 'FontWeight', 'bold');
legend('LED Intensity', 'Detected Trial Start', 'Location', 'best');

%% User Verification for Each Trial
fprintf('\n=== TRIAL VERIFICATION ===\n');

for tt = 1:num_of_trials
    fprintf('\n--- Verifying Trial %d/%d ---\n', tt, num_of_trials);
    
    current_frame = trials_start(tt);
    current_time = timestamps(current_frame);
    
    % Define window: ±20 seconds around trial start
    [~, start_idx] = min(abs(timestamps - (current_time - 20)));
    [~, end_idx] = min(abs(timestamps - (current_time + 20)));
    
    % Ensure indices within bounds
    start_idx = max(1, start_idx);
    end_idx = min(length(timestamps), end_idx);
    
    % Extract frames for verification window
    frames_needed = end_idx - start_idx + 1;
    window_frames = start_idx:end_idx;
    
    % Read LED intensity for window
    v_verify = VideoReader(fullfile(behav_path, video_name));
    v_verify.CurrentTime = timestamps(start_idx);
    
    window_tc_roi = zeros(frames_needed, 1);
    frame_count = 1;
    
    while hasFrame(v_verify) && frame_count <= frames_needed
        frame = readFrame(v_verify);
        frame_gray = double(frame(:, :, 1));
        roi_pixels = frame_gray(roi_mask);
        window_tc_roi(frame_count) = mean(roi_pixels, 'omitnan');
        frame_count = frame_count + 1;
    end
    
    % Plot verification window
    fig_trial = figure('Name', sprintf('Trial %d Verification', tt), ...
        'Position', [100, 100, 1000, 400]);
    plot(timestamps(window_frames), window_tc_roi, 'b-', 'LineWidth', 1.5);
    hold on;
    
    % Mark detected trial start
    marker_idx = current_frame - start_idx + 1;
    if marker_idx > 0 && marker_idx <= length(window_tc_roi)
        scatter(current_time, window_tc_roi(marker_idx), 150, 'r', 'filled', ...
            'MarkerEdgeColor', 'k', 'LineWidth', 1.5);
    end
    
    % Add vertical line at trial start
    ylims = ylim;
    plot([current_time current_time], ylims, 'r--', 'LineWidth', 2);
    
    grid on;
    xlabel('Time (seconds)', 'FontSize', 11);
    ylabel('LED Intensity (a.u.)', 'FontSize', 11);
    title(sprintf('Trial %d Verification (±20s window)', tt), ...
        'FontSize', 12, 'FontWeight', 'bold');
    legend('LED Intensity', 'Detected Start', 'Trial Start Time', 'Location', 'best');
    
    % User confirmation
    choice = questdlg(sprintf('Is Trial %d start correct?', tt), ...
        sprintf('Verify Trial %d', tt), ...
        'Yes', 'No - Manual Adjust', 'Yes');
    
    % Handle manual adjustment
    if strcmp(choice, 'No - Manual Adjust')
        fprintf('Click on the correct start point for Trial %d\n', tt);
        title(sprintf('CLICK on correct start point for Trial %d', tt), ...
            'FontSize', 12, 'FontWeight', 'bold', 'Color', 'r');
        
        [x_click, ~] = ginput(1);
        [~, new_idx] = min(abs(timestamps(window_frames) - x_click));
        trials_start(tt) = window_frames(new_idx);
        
        fprintf('Trial %d manually adjusted to frame %d (time = %.2f s)\n', ...
            tt, trials_start(tt), timestamps(trials_start(tt)));
        
        % Replot with updated marker
        close(fig_trial);
        fig_trial = figure('Name', sprintf('Trial %d Updated', tt), ...
            'Position', [100, 100, 1000, 400]);
        plot(timestamps(window_frames), window_tc_roi, 'b-', 'LineWidth', 1.5);
        hold on;
        
        new_marker_idx = trials_start(tt) - start_idx + 1;
        if new_marker_idx > 0 && new_marker_idx <= length(window_tc_roi)
            scatter(timestamps(trials_start(tt)), window_tc_roi(new_marker_idx), ...
                150, 'g', 'filled', 'MarkerEdgeColor', 'k', 'LineWidth', 1.5);
        end
        
        grid on;
        xlabel('Time (seconds)', 'FontSize', 11);
        ylabel('LED Intensity (a.u.)', 'FontSize', 11);
        title(sprintf('Trial %d - UPDATED Start', tt), ...
            'FontSize', 12, 'FontWeight', 'bold');
        legend('LED Intensity', 'Corrected Start', 'Location', 'best');
        pause(1.5);
    end
    
    close(fig_trial);
end

%% Save Results
fprintf('\n=== SAVING RESULTS ===\n');

cd(brain_path);
save('trials_start', 'trials_start');

% Save first trial specifically (legacy compatibility)
LED_start = trials_start(1);
save(fullfile(brain_path, ['LED_start_', video_name]), 'LED_start');

fprintf('Trial start frames saved successfully\n');
fprintf('Summary:\n');
for tt = 1:num_of_trials
    fprintf('  Trial %d: Frame %d (%.2f s)\n', ...
        tt, trials_start(tt), timestamps(trials_start(tt)));
end

end