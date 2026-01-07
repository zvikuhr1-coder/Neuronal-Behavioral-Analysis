function [x_coords_filtered, y_coords_filtered] = removeOutsideArenaPoints2(behav_path, x_coords, y_coords)
% REMOVEOUTSIDEARENAPOINTS2 Filter tracking coordinates outside arena boundaries
%
% Syntax:
%   [x_filtered, y_filtered] = removeOutsideArenaPoints2(behav_path, x_coords, y_coords)
%
% Description:
%   Removes tracking points that fall outside the experimentally defined arena
%   boundaries by replacing them with NaN values. Uses the polygon ROI created
%   by define_arena_roi to determine valid spatial regions. This filtering is
%   essential for removing tracking artifacts that occur when the animal is
%   detected outside the arena or when DLC makes erroneous predictions.
%
% Inputs:
%   behav_path - String specifying directory containing arenaPolygon.mat
%   x_coords - Nx1 array of X coordinates (pixels)
%   y_coords - Nx1 array of Y coordinates (pixels)
%
% Outputs:
%   x_coords_filtered - Nx1 array of X coordinates (NaN for points outside arena)
%   y_coords_filtered - Nx1 array of Y coordinates (NaN for points outside arena)
%
% Algorithm:
%   1. Load arena polygon ROI definition
%   2. Test each coordinate pair for inclusion in polygon
%   3. Replace points outside polygon with NaN
%   4. Report filtering statistics
%
% Example:
%   behav_path = 'D:\AD_6\AD21\1L1R\TEST';
%   x_raw = [100, 150, 500, 200, 250];  % Some points outside arena
%   y_raw = [100, 150, 50, 200, 250];
%   [x_clean, y_clean] = removeOutsideArenaPoints2(behav_path, x_raw, y_raw);
%
% Notes:
%   - Requires arenaPolygon.mat to exist (run define_arena_roi first)
%   - Points exactly on polygon boundary are considered inside
%   - NaN values in input are preserved in output
%   - Filtering prevents tracking artifacts from affecting analysis
%   - High percentage of filtered points may indicate incorrect arena definition
%
% See also: define_arena_roi, inpolygon, isnan

% Validate inputs
if length(x_coords) ~= length(y_coords)
    error('X and Y coordinate arrays must have same length');
end

% Load arena polygon
cd(behav_path);
if ~exist('arenaPolygon.mat', 'file')
    error('arenaPolygon.mat not found. Run define_arena_roi first.');
end

load('arenaPolygon.mat', 'arena_polygon');

% Extract polygon vertices
if isobject(arena_polygon)
    % Handle polygon ROI object
    poly_x = arena_polygon.Position(:, 1);
    poly_y = arena_polygon.Position(:, 2);
else
    % Handle stored polygon structure
    poly_x = arena_polygon(:, 1);
    poly_y = arena_polygon(:, 2);
end

fprintf('Arena polygon loaded with %d vertices\n', length(poly_x));

% Initialize output arrays (copy input)
x_coords_filtered = x_coords;
y_coords_filtered = y_coords;

% Count initial NaN values
initial_nan_count = sum(isnan(x_coords) | isnan(y_coords));

% Test each point for inclusion in polygon
valid_indices = ~isnan(x_coords) & ~isnan(y_coords);
points_to_test = find(valid_indices);

% Use inpolygon for efficient batch testing
inside_arena = inpolygon(x_coords(valid_indices), y_coords(valid_indices), ...
    poly_x, poly_y);

% Create full-length inside vector
inside_full = false(size(x_coords));
inside_full(points_to_test) = inside_arena;

% Set points outside arena to NaN
outside_arena = valid_indices & ~inside_full;
x_coords_filtered(outside_arena) = nan;
y_coords_filtered(outside_arena) = nan;

% Report filtering statistics
points_filtered = sum(outside_arena);
total_valid_points = sum(valid_indices);
final_nan_count = sum(isnan(x_coords_filtered) | isnan(y_coords_filtered));

fprintf('=== ARENA FILTERING RESULTS ===\n');
fprintf('Initial NaN points: %d (%.1f%%)\n', ...
    initial_nan_count, 100 * initial_nan_count / length(x_coords));
fprintf('Points outside arena: %d (%.1f%% of valid points)\n', ...
    points_filtered, 100 * points_filtered / total_valid_points);
fprintf('Final NaN points: %d (%.1f%%)\n', ...
    final_nan_count, 100 * final_nan_count / length(x_coords));
fprintf('Valid points remaining: %d (%.1f%%)\n', ...
    sum(~isnan(x_coords_filtered)), ...
    100 * sum(~isnan(x_coords_filtered)) / length(x_coords));

% Warning if too many points filtered
if points_filtered > 0.2 * total_valid_points
    warning(['More than 20%% of points filtered. ', ...
        'Consider redrawing arena polygon to be more inclusive.']);
end

end