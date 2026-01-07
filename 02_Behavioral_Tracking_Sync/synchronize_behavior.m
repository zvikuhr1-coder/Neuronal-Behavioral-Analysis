function synchronize_behavior_imaging(behav_path)
% SYNCHRONIZE_BEHAVIOR_IMAGING Align behavioral tracking with imaging acquisition
%
% Syntax:
%   synchronize_behavior_imaging(behav_path)
%
% Description:
%   Synchronizes DeepLabCut behavioral tracking coordinates with calcium imaging
%   frames by temporally aligning video timestamps with imaging acquisition times.
%   The function handles multiple trials, filters points outside arena boundaries,
%   corrects tracking outliers, and interpolates missing data to produce
%   frame-by-frame aligned behavioral and neural activity data.
%
% Input:
%   behav_path - String specifying directory containing:
%                - trials_start.mat (trial timing)
%                - timestamps.mat (video frame times)
%                - tracking CSV (DeepLabCut output)
%                - arenaPolygon.mat (arena boundaries)
%                - Matt_files/tc_all_brain_areas_CORRECTED*.mat (imaging data)
%
% Output Files:
%   Located in Matt_files subdirectory:
%   - vec_for_vid_new.mat: Frame alignment indices for entire session
%   - vec_for_intorp_new.mat: Interpolation markers (NaN for misaligned frames)
%   - correctedTrackingData.mat: Final synchronized X/Y coordinates
%                                'x_CORRECTED_ALL', 'y_CORRECTED_ALL'
%   - tc_all_brain_areas_CORRECTED_ALL.mat: Imaging data aligned to behavior
%   - xy_post_synched.mat: Intermediate synchronization results
%
% Algorithm:
%   1. Load trial timing, timestamps, and tracking data
%   2. Create temporal mapping between imaging frames and video frames
%   3. For each trial:
%      a. Adjust timestamps relative to trial start
%      b. Map each imaging frame to nearest video frame
%      c. Flag frames with >20ms temporal mismatch
%   4. Extract tracking coordinates for mapped frames
%   5. Filter coordinates outside arena boundaries
%   6. Interpolate NaN gaps from flagged frames
%   7. Correct tracking outliers using moving window method
%   8. Concatenate all trials into single aligned dataset
%
% Synchronization Parameters:
%   - Imaging frame rate: 10 Hz (600 frames per 5-minute trial)
%   - Maximum temporal mismatch: 20 ms (frames beyond this marked for interpolation)
%   - Outlier correction window: 15 frames
%   - Outlier deviation threshold: 15 pixels
%
% Example:
%   behav_path = 'D:\AD_6\AD21\1L1R\TEST';
%   synchronize_behavior_imaging(behav_path);
%
% Notes:
%   - Requires prior completion of pipeline steps 1-4
%   - Number of trials determined from tc_all_brain_areas_CORRECTED*.mat files
%   - DLC tracking should use median of multiple body parts for robustness
%   - Generates plots showing original vs corrected tracking for each trial
%
% See also: detect_trial_starts, extract_video_timestamps, 
%           tracking_outlier_correction, removeOutsideArenaPoints2

%% Initialize Paths and Parameters
brain_path = fullfile(behav_path, 'Matt_files');
cd(brain_path);

% Load trial timing information
if ~exist('trials_start.mat', 'file')
    error('trials_start.mat not found. Run detect_trial_starts first.');
end
load('trials_start.mat', 'trials_start');

% Load video timestamps
if ~exist('timestamps.mat', 'file')
    error('timestamps.mat not found. Run extract_video_timestamps first.');
end
load('timestamps.mat', 'timestamps');

% Imaging parameters
num_of_trials = 2;  % Adjust based on experimental design
fps = 10;           % Imaging frame rate (Hz)
fpm = fps * 60;     % Frames per minute

% Load first trial imaging data to determine dimensions
load('tc_all_brain_areas_CORRECTED1.mat', 'tc_all_brain_areas_CORRECTED');
frames_per_trial = size(tc_all_brain_areas_CORRECTED, 2);
num_of_frames = frames_per_trial * num_of_trials;
number_of_mins = num_of_frames / fpm;

fprintf('=== SYNCHRONIZATION PARAMETERS ===\n');
fprintf('Number of trials: %d\n', num_of_trials);
fprintf('Frames per trial: %d\n', frames_per_trial);
fprintf('Total imaging frames: %d\n', num_of_frames);
fprintf('Total duration: %.1f minutes\n', number_of_mins);

%% Load Behavioral Tracking Data
cd(behav_path);

% Locate DLC tracking CSV file
csv_table = dir('*.csv');
if isempty(csv_table)
    error('No CSV tracking file found in %s', behav_path);
end

csv_name = csv_table.name;
fprintf('Loading tracking data from: %s\n', csv_name);

% Read tracking data
tracking_table = readtable(csv_name);
tracking_array = table2array(tracking_table);

% Extract coordinates (median across multiple tracked points for robustness)
% Assuming columns 5:3:11 are X coords, 6:3:12 are Y coords for multiple body parts
x_coord_raw = median(tracking_array(:, 5:3:11), 2);
y_coord_raw = median(tracking_array(:, 6:3:12), 2);

fprintf('Loaded %d tracking points\n', length(x_coord_raw));

%% Filter Arena Boundaries
cd(brain_path);

fprintf('\n=== FILTERING ARENA BOUNDARIES ===\n');
[x_coords_filtered, y_coords_filtered] = removeOutsideArenaPoints2(behav_path, ...
    x_coord_raw, y_coord_raw);

%% Temporal Alignment: Imaging → Video Frame Mapping
fprintf('\n=== TEMPORAL ALIGNMENT ===\n');

% Create idealized imaging timeline (evenly spaced frames)
brain_vec = linspace(0, 60 * number_of_mins, num_of_frames);

% Initialize alignment arrays
timestamp_adjust = [];      % Timestamps relative to each trial start
vec_for_vid = [];          % Video frame indices for each imaging frame
vec_for_intorp = [];       % Copy with NaN for poorly aligned frames
temp_intrv_vec = [];       % Temporal mismatch for each alignment

% Process each trial independently
for trial = 1:num_of_trials
    fprintf('Aligning trial %d/%d...\n', trial, num_of_trials);
    
    % Adjust timestamps relative to trial start (with 15-frame buffer)
    timestamps_start = timestamps(trials_start(trial) - 15);
    timestamp_adjust(trial, :) = timestamps - timestamps_start;
    
    % Initialize arrays for this trial
    vec_for_vid(trial, :) = nan(1, frames_per_trial);
    temp_intrv_vec(trial, :) = nan(1, frames_per_trial);
    
    % Map each imaging frame to nearest video frame
    for frame = 1:frames_per_trial
        % Find video frame with minimum temporal distance
        brain_time = brain_vec(frame);
        [time_interval, video_idx] = min(abs(brain_time - timestamp_adjust(trial, :)));
        
        vec_for_vid(trial, frame) = video_idx;
        temp_intrv_vec(trial, frame) = time_interval;
    end
    
    % Flag frames with poor temporal alignment (>20ms mismatch)
    poor_alignment = find(temp_intrv_vec(trial, :) > 0.02);
    fprintf('  Frames with >20ms mismatch: %d (%.1f%%)\n', ...
        length(poor_alignment), 100 * length(poor_alignment) / frames_per_trial);
    
    % Create interpolation version (NaN for poorly aligned frames)
    vec_for_intorp(trial, :) = vec_for_vid(trial, :);
    vec_for_intorp(trial, poor_alignment) = nan;
end

% Reshape into single continuous vectors
vec_for_vid_new = reshape(vec_for_vid.', 1, []);
vec_for_intorp_new = reshape(vec_for_intorp.', 1, []);

% Save alignment vectors
cd(behav_path);
save('vec_for_intorp_new', 'vec_for_intorp_new');
save('vec_for_vid_new', 'vec_for_vid_new');

%% Synchronize Tracking Coordinates
fprintf('\n=== SYNCHRONIZING COORDINATES ===\n');

cd(brain_path);

% Initialize output arrays
xpos_sync_all = [];
ypos_sync_all = [];

% Process each trial
for trial = 1:num_of_trials
    fprintf('Processing trial %d/%d\n', trial, num_of_trials);
    
    % Map behavioral coordinates to imaging frames
    xpos_sync = x_coords_filtered(vec_for_vid(trial, :), 1);
    ypos_sync = y_coords_filtered(vec_for_vid(trial, :), 1);
    
    % Apply NaN mask for poorly aligned frames
    xpos_sync(isnan(vec_for_intorp(trial, :))) = nan;
    ypos_sync(isnan(vec_for_intorp(trial, :))) = nan;
    
    % Interpolate NaN gaps
    valid_indices = ~isnan(xpos_sync);
    
    if sum(valid_indices) < 2
        warning('Trial %d has too few valid points for interpolation', trial);
        xpos_interp = xpos_sync;
        ypos_interp = ypos_sync;
    else
        xpos_interp = interp1(find(valid_indices), xpos_sync(valid_indices), ...
            1:numel(xpos_sync), 'linear', 'extrap');
        ypos_interp = interp1(find(valid_indices), ypos_sync(valid_indices), ...
            1:numel(ypos_sync), 'linear', 'extrap');
    end
    
    % Correct tracking outliers
    tracking_data = [xpos_interp; ypos_interp];
    window_size = 15;
    deviation_threshold = 15;
    corrected_tracking = tracking_outlier_correction(tracking_data, ...
        window_size, deviation_threshold);
    
    % Visualize correction
    fig = figure('Name', sprintf('Trial %d Tracking Correction', trial), ...
        'Position', [100, 100, 1400, 500]);
    
    % Original trajectory
    subplot(1, 2, 1);
    plot(tracking_data(1, :), tracking_data(2, :), 'r-', 'LineWidth', 1.5);
    axis equal;
    grid on;
    title('Original Tracking', 'FontSize', 12, 'FontWeight', 'bold');
    xlabel('X Position (pixels)', 'FontSize', 11);
    ylabel('Y Position (pixels)', 'FontSize', 11);
    
    % Corrected trajectory
    subplot(1, 2, 2);
    plot(corrected_tracking(1, :), corrected_tracking(2, :), 'b-', 'LineWidth', 1.5);
    axis equal;
    grid on;
    title('Corrected Tracking', 'FontSize', 12, 'FontWeight', 'bold');
    xlabel('X Position (pixels)', 'FontSize', 11);
    ylabel('Y Position (pixels)', 'FontSize', 11);
    
    % Store corrected data
    xpos_sync_all(trial, :) = corrected_tracking(1, :);
    ypos_sync_all(trial, :) = corrected_tracking(2, :);
end

%% Concatenate All Trials
fprintf('\n=== CONCATENATING TRIALS ===\n');

final_xpos_sync = xpos_sync_all;
final_ypos_sync = ypos_sync_all;

% Initialize combined arrays
tc_all_brain_areas_CORRECTED_ALL = [];
x_CORRECTED_ALL = [];
y_CORRECTED_ALL = [];

% Load and concatenate each trial's imaging data
cd(brain_path);
for trial = 1:num_of_trials
    % Load imaging data for this trial
    tc_file = sprintf('tc_all_brain_areas_CORRECTED%d.mat', trial);
    if ~exist(tc_file, 'file')
        warning('Missing imaging file: %s', tc_file);
        continue;
    end
    
    load(tc_file, 'tc_all_brain_areas_CORRECTED');
    
    % Concatenate imaging and behavioral data
    tc_all_brain_areas_CORRECTED_ALL = [tc_all_brain_areas_CORRECTED_ALL, ...
        tc_all_brain_areas_CORRECTED];
    x_CORRECTED_ALL = [x_CORRECTED_ALL, final_xpos_sync(trial, :)];
    y_CORRECTED_ALL = [y_CORRECTED_ALL, final_ypos_sync(trial, :)];
end

%% Save Final Outputs
fprintf('\n=== SAVING RESULTS ===\n');

% Save corrected tracking coordinates
save('correctedTrackingData', 'x_CORRECTED_ALL', 'y_CORRECTED_ALL');
fprintf('Saved: correctedTrackingData.mat\n');

% Save combined imaging data
save('tc_all_brain_areas_CORRECTED_ALL', 'tc_all_brain_areas_CORRECTED_ALL');
fprintf('Saved: tc_all_brain_areas_CORRECTED_ALL.mat\n');

% Save intermediate synchronization data (legacy compatibility)
save('xy_post_synched', 'xpos_sync', 'ypos_sync', 'xpos_sync_all', 'ypos_sync_all');
fprintf('Saved: xy_post_synched.mat\n');

%% Summary
fprintf('\n=== SYNCHRONIZATION COMPLETE ===\n');
fprintf('Total aligned frames: %d\n', length(x_CORRECTED_ALL));
fprintf('Behavioral data shape: %d coordinates\n', length(x_CORRECTED_ALL));
fprintf('Imaging data shape: %d ROIs × %d frames\n', ...
    size(tc_all_brain_areas_CORRECTED_ALL, 1), size(tc_all_brain_areas_CORRECTED_ALL, 2));
fprintf('Data ready for downstream analysis\n');

end