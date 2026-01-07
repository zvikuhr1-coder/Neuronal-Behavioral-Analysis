function corrected_data = tracking_outlier_correction(tracking_data, window_size, deviation_threshold)
% TRACKING_OUTLIER_CORRECTION Remove tracking outliers via moving window interpolation
%
% Syntax:
%   corrected_data = tracking_outlier_correction(tracking_data, window_size, deviation_threshold)
%
% Description:
%   Detects and corrects outliers in 2D tracking data using a moving average
%   approach. Outliers are identified when points deviate excessively from
%   the smoothed trajectory, then replaced via linear interpolation between
%   neighboring valid points. Essential for cleaning DLC tracking artifacts.
%
% Inputs:
%   tracking_data - 2xN matrix where row 1 = X coordinates, row 2 = Y coordinates
%   window_size - Integer specifying moving average window (frames)
%                 Typical value: 15 (adjust based on frame rate)
%   deviation_threshold - Maximum allowed deviation from smoothed trajectory (pixels)
%                        Typical value: 15 (adjust based on arena size)
%
% Output:
%   corrected_data - 2xN matrix with outliers replaced by interpolated values
%
% Algorithm:
%   1. Compute moving average trajectory for X and Y separately
%   2. Calculate deviation of each point from smoothed trajectory
%   3. Mark points exceeding threshold as outliers
%   4. Replace outliers via linear interpolation between nearest valid neighbors
%   5. Handle edge cases (outliers at start/end of sequence)
%
% Example:
%   % Tracking data with outliers
%   x = [10 11 12 50 14 15 16];  % Frame 4 is outlier
%   y = [20 21 22 23 24 80 26];  % Frame 6 is outlier
%   data = [x; y];
%   
%   corrected = tracking_outlier_correction(data, 3, 10);
%
% Notes:
%   - Window size should be odd for symmetric smoothing
%   - Smaller thresholds = more aggressive correction (may remove valid data)
%   - Larger thresholds = preserve more original data (may keep some outliers)
%   - For high-speed movements, consider larger window_size
%   - Works best when outliers are sparse (< 10% of frames)
%
% See also: movmean, interp1

% Validate inputs
if size(tracking_data, 1) ~= 2
    error('tracking_data must be 2xN matrix (X and Y coordinates)');
end

num_frames = size(tracking_data, 2);
corrected_data = tracking_data;

% Compute smoothed trajectory using moving average
smooth_x = movmean(tracking_data(1, :), window_size);
smooth_y = movmean(tracking_data(2, :), window_size);

% Calculate deviations from smoothed trajectory
deviations_x = abs(tracking_data(1, :) - smooth_x);
deviations_y = abs(tracking_data(2, :) - smooth_y);

% Identify outliers (either X or Y deviation exceeds threshold)
outliers = (deviations_x > deviation_threshold) | (deviations_y > deviation_threshold);

fprintf('Detected %d outliers (%.1f%% of frames)\n', ...
    sum(outliers), 100 * sum(outliers) / num_frames);

% Correct each outlier via interpolation
for i = 1:num_frames
    if outliers(i)
        % Find nearest valid point before outlier
        prev_index = find(~outliers(1:i-1), 1, 'last');
        
        % Find nearest valid point after outlier
        next_index = find(~outliers(i+1:end), 1, 'first') + i;
        
        % Handle edge cases
        if isempty(prev_index)
            prev_index = 1;  % Use first frame if no prior valid points
        end
        
        if isempty(next_index)
            next_index = num_frames;  % Use last frame if no subsequent valid points
        end
        
        % Linear interpolation between valid neighbors
        weight = (i - prev_index) / (next_index - prev_index);
        corrected_data(:, i) = corrected_data(:, prev_index) + ...
            weight * (corrected_data(:, next_index) - corrected_data(:, prev_index));
    end
end

end