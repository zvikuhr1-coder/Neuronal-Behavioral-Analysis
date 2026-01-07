function arena_polygon = define_arena_roi(behav_path)
% DEFINE_ARENA_ROI Interactive polygon drawing for arena boundary definition
%
% Syntax:
%   arena_polygon = define_arena_roi(behav_path)
%
% Description:
%   Displays the background frame and prompts user to draw a polygon defining
%   the arena boundaries. This ROI is used to filter out tracking points that
%   fall outside the experimental arena, removing artifacts and invalid
%   position data.
%
% Input:
%   behav_path - String specifying directory containing background_frame.mat
%
% Output:
%   arena_polygon - MATLAB polygon object containing arena boundary coordinates
%
% Output Files:
%   arenaPolygon.mat - Contains 'arenaPolygon' (polygon ROI object)
%
% Interactive Use:
%   1. Function displays background frame
%   2. User draws polygon by clicking vertices on arena perimeter
%   3. Double-click to complete polygon
%   4. Polygon is automatically saved for later use
%
% Example:
%   behav_path = 'D:\AD_6\AD21\1L1R\TEST';
%   arena = define_arena_roi(behav_path);
%
% Notes:
%   - Requires background_frame.mat to exist (run process_background first)
%   - Polygon should encompass entire usable arena area
%   - More vertices = more accurate boundary definition
%   - Saved polygon can be loaded for filtering: load('arenaPolygon.mat')
%
% See also: process_background, drawpolygon, images.roi.Polygon

% Change to behavioral data directory
cd(behav_path);

% Load background frame
if ~exist('background_frame.mat', 'file')
    error('background_frame.mat not found. Run process_background first.');
end

load('background_frame.mat', 'background_frame');

% Display background frame
figure('Name', 'Arena ROI Definition', 'NumberTitle', 'off');
imagesc(background_frame);
axis image;
hold on;
title('Draw polygon around arena perimeter');
xlabel('X coordinate (pixels)');
ylabel('Y coordinate (pixels)');

% Interactive polygon drawing
arena_polygon = drawpolygon('Label', 'Arena', 'Color', 'r', 'LineWidth', 2);

% Wait for user to complete polygon
fprintf('Draw polygon by clicking vertices. Double-click to finish.\n');
wait(arena_polygon);

% Save polygon ROI
save('arenaPolygon', 'arena_polygon');

fprintf('Arena polygon saved successfully.\n');
fprintf('Polygon has %d vertices.\n', size(arena_polygon.Position, 1));

end