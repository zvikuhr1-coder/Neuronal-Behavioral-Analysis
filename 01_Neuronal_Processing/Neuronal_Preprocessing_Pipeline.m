%% Fiber Photometry Calcium Imaging Analysis Pipeline
% =========================================================================
% This pipeline processes raw calcium imaging data from fiber photometry
% experiments with dual-wavelength hemodynamic correction.
%
% PIPELINE OVERVIEW:
% 1. Extract reference images from raw data
% 2. Define regions of interest (ROIs) for each recording site
% 3. Extract and correct calcium signals across all trials
%
% REQUIREMENTS:
%   - extract_reference_image.m
%   - define_recording_sites.m
%   - extract_calcium_signals.m
%   - read_dcam_file.m
%   - adjust_brightness.m
%
% Author: [Your Name]
% GitHub: [Repository URL]
% =========================================================================

%% Setup
clear all; close all; clc;

% Path to folder containing raw DCAM files
data_path = 'C:\Path\To\Your\Data\Folder';

% Analysis parameters
params.dual_wavelength = true;  % Dual-wavelength hemodynamic correction
params.show_plots = false;       % Skip plotting for GitHub documentation

fprintf('===== FIBER PHOTOMETRY ANALYSIS PIPELINE =====\n\n');
fprintf('Data location: %s\n\n', data_path);

%% STEP 1: Extract Reference Image
% =========================================================================
% Creates anatomical reference showing fiber array layout
% Output: reference_image.mat (256x256 downsampled, 512x512 full resolution)
% =========================================================================

fprintf('STEP 1: Extracting reference image...\n');
extract_reference_image(data_path);
fprintf('✓ Reference image created\n\n');

%% STEP 2: Define Recording Sites
% =========================================================================
% Interactive ROI definition for 48 recording sites (4x12 grid)
% Sites correspond to different brain regions
% Output: recording_sites.mat, chamber_mask.mat
% =========================================================================

fprintf('STEP 2: Defining recording sites (ROIs)...\n');
fprintf('Interactive step: Draw chamber boundary and adjust ROI positions\n');
define_recording_sites(data_path);
fprintf('✓ Recording sites defined\n\n');

%% STEP 3: Extract Calcium Signals
% =========================================================================
% Process all trials:
% - Read raw DCAM frames
% - Separate purple (calcium) and blue (hemodynamic) channels
% - Apply hemodynamic correction: ΔF/F = (Purple - Blue) / baseline
% - Smooth signals with 5-frame moving average
% 
% Output per trial:
% - trial_N_purple.mat (calcium-sensitive channel)
% - trial_N_blue.mat (hemodynamic reference)
% - trial_N_corrected.mat (corrected signal, 48 sites × timepoints)
% =========================================================================

fprintf('STEP 3: Extracting and correcting calcium signals...\n');
reference_path = fullfile(data_path, 'reference');
num_trials = extract_calcium_signals(reference_path, data_path, params);
fprintf('✓ Processed %d trials\n\n', num_trials);

%% Pipeline Complete
fprintf('===== ANALYSIS COMPLETE =====\n');
fprintf('Output structure:\n');
fprintf('  reference/\n');
fprintf('    - reference_image.mat\n');
fprintf('    - recording_sites.mat\n');
fprintf('    - chamber_mask.mat\n');
fprintf('  processed/\n');
fprintf('    - trial_N_purple.mat\n');
fprintf('    - trial_N_blue.mat\n');
fprintf('    - trial_N_corrected.mat\n\n');

fprintf('Data format: [48 recording sites × timepoints]\n');
fprintf('Signal type: Normalized ΔF/F₀ with hemodynamic correction\n');
