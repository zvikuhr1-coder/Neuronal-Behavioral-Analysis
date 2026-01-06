%% Calcium Imaging Data Processing Pipeline
% This script processes raw calcium imaging data from DCAM files through
% a complete pipeline: creating reference images, defining ROIs, and 
% extracting time series data for each brain region across trials.
%
% OVERVIEW OF THE PROCESSING PIPELINE:
% 1. Create reference images (green channel) from the first DCAM file
% 2. Define brain regions of interest (ROIs) on the reference image
% 3. Process all trial DCAM files to extract time series for each ROI
%
% REQUIRED FUNCTIONS (must be in MATLAB path):
%   - create_green_files2.m
%   - Select_Brain_Areas_ROIs_new2.m
%   - Green_and_Brain_rois.m
%   - create_matt_files3.m
%   - readDCAM_v4.m (or readDCAM_v3.m for non-control data)
%   - adjustBrightness.m
%
% Author: [Your Name]
% Date: [Date]
% GitHub: [Your GitHub URL]

%% STEP 0: SETUP AND CONFIGURATION
% Clear workspace and command window for a fresh start
clear all;
close all;
clc;

% =========================================================================
% USER CONFIGURATION - MODIFY THESE PARAMETERS FOR YOUR EXPERIMENT
% =========================================================================

% Path to the folder containing your DCAM files (raw calcium imaging data)
% This folder should contain files named like: 2024XXXX_XXXXXX.dcimg
behav_path = 'C:\Path\To\Your\Data\Folder';

% Control mode flag:
% control = 0: Single-wavelength imaging (one channel per frame)
% control = 1: Dual-wavelength imaging (alternating purple/blue channels)
%              Used for hemodynamic correction in some imaging systems
control = 1;

% Plotting flag:
% plot_flag = 1: Display time series plots for each trial (useful for QC)
% plot_flag = 0: Skip plotting (faster processing)
plot_flag = 1;

% =========================================================================

fprintf('=============================================================\n');
fprintf('CALCIUM IMAGING PROCESSING PIPELINE\n');
fprintf('=============================================================\n');
fprintf('Data path: %s\n', behav_path);
fprintf('Control mode: %d\n', control);
fprintf('Plotting enabled: %d\n\n', plot_flag);

%% STEP 1: CREATE GREEN REFERENCE IMAGES
% =========================================================================
% PURPOSE: Generate reference images from the first DCAM file
% 
% WHAT THIS DOES:
% - Reads the first 2 frames from the first DCAM file in the folder
% - Creates a downsampled (256x256) version for ROI selection
% - Creates a full-resolution (512x512) version for visualization
% - Saves these images in a new 'green' subfolder
%
% WHY WE NEED THIS:
% The "green" reference image provides a stable anatomical reference
% showing the fiber array layout. We'll use this to define which regions
% of the image correspond to which brain areas.
%
% OUTPUT FILES (in green/ subfolder):
% - green_ds.mat: Downsampled reference image (256x256 pixels)
% - green.mat: Full resolution reference image (512x512 pixels)
% - Gs.mat: Contains g1 and g2 (first two frames)
% =========================================================================

fprintf('STEP 1: Creating green reference images...\n');
fprintf('-----------------------------------------------------------\n');
fprintf('Reading first DCAM file to extract reference frames...\n');

try
    create_green_files2(behav_path);
    fprintf('✓ Green reference images created successfully\n');
    fprintf('  Files saved in: %s\\green\\\n\n', behav_path);
catch ME
    error('Error creating green files: %s\n', ME.message);
end

%% STEP 2: DEFINE BRAIN REGIONS OF INTEREST (ROIs)
% =========================================================================
% PURPOSE: Interactively define which parts of the image correspond to
%          which brain regions
%
% WHAT THIS DOES:
% 1. Displays the green reference image
% 2. Allows you to select a rectangular chamber region (area with signal)
% 3. Shows an initial grid of 48 circular ROIs (4 rows × 12 columns)
% 4. Lets you manually adjust the size and position of corner ROIs
% 5. Automatically interpolates positions for intermediate ROIs
%
% THE 48 ROI GRID STRUCTURE:
% The ROIs are arranged in a 4×12 grid representing different brain areas:
% Row 1: S1BF, CPU, S1BF, x, GP, x, x, x, x, M1, Re, Re
% Row 2: BLA, BLA, S1BF, CeM, RT, S1BF, VPM, CA3, CA3, CA1, DG, Re
% Row 3: x, PRh, DLEnt, DIEnt, DIEnt, DIEnt, DG, Ment, DG, Post, x, RSD
% Row 4: x, DLEnt, Ment, TEA, CEnt, CEnt, V1, Prs, Post, x, RSD, x
%
% Where:
% - S1BF: Primary Somatosensory Cortex Barrel Field
% - CPU: Caudate Putamen
% - GP: Globus Pallidus
% - M1: Primary Motor Cortex
% - Re: Nucleus Reuniens
% - BLA: Basolateral Amygdala
% - CeM: Central Medial Amygdala
% - RT: Reticular Thalamic Nucleus
% - VPM: Ventral Posteromedial Thalamic Nucleus
% - CA1/CA3: Hippocampal regions
% - DG: Dentate Gyrus
% - And others...
% - x: placeholder for unused positions
%
% USER INTERACTION REQUIRED:
% 1. First, draw a rectangle around the chamber (fiber array area)
% 2. Then, adjust the red circles on the displayed image:
%    - Click and drag circles to reposition them
%    - Drag circle edges to resize them
%    - Focus on the corner circles (positions 1, 12, 13, 24, 25, 36, 37, 48)
%    - Intermediate circles will be automatically interpolated
% 3. Use the brightness slider at the bottom to adjust image contrast
% 4. Press ENTER in the command window when finished
%
% OUTPUT FILES (in green/ subfolder):
% - pixels_to_remove.mat: Mask of pixels outside the chamber
% - brain_ROIs.mat: Structure containing center, radius, and pixel masks
%                   for each of the 48 brain regions
% =========================================================================

fprintf('STEP 2: Defining brain regions of interest...\n');
fprintf('-----------------------------------------------------------\n');
fprintf('INTERACTIVE STEP - User input required!\n\n');

fprintf('Instructions:\n');
fprintf('1. A figure will open showing the reference image\n');
fprintf('2. Draw a rectangle around the fiber array chamber\n');
fprintf('3. Another figure will show 48 circular ROIs on the image\n');
fprintf('4. Adjust the RED circles (corners: 1,12,13,24,25,36,37,48)\n');
fprintf('   - Drag circles to move them\n');
fprintf('   - Drag circle edges to resize them\n');
fprintf('5. Use the brightness slider to adjust image contrast\n');
fprintf('6. Press ENTER in the command window when done\n\n');

fprintf('Opening ROI selection interface...\n');

try
    Green_and_Brain_rois(behav_path);
    fprintf('✓ Brain ROIs defined successfully\n');
    fprintf('  48 ROIs saved in: %s\\green\\brain_ROIs.mat\n\n', behav_path);
catch ME
    error('Error defining ROIs: %s\n', ME.message);
end

%% STEP 3: PROCESS ALL TRIALS AND EXTRACT TIME SERIES
% =========================================================================
% PURPOSE: Process all DCAM files and extract calcium signal time series
%          for each brain region
%
% WHAT THIS DOES:
% For each DCAM file (trial) in the folder:
% 1. Read all frames from the file
% 2. Apply the chamber mask (remove pixels outside the fiber array)
% 3. Downsample frames from 512×512 to 256×256 pixels
% 4. Calculate normalized fluorescence (ΔF/F):
%    - F₀ = median fluorescence across frames (baseline)
%    - ΔF/F = (F - F₀) / F₀ for each timepoint
% 
% FOR SINGLE-WAVELENGTH DATA (control = 0):
% - Process frames as-is
% - Save time series for all pixels in each ROI
%
% FOR DUAL-WAVELENGTH DATA (control = 1):
% - Separate alternating frames into two channels:
%   * Purple channel: Calcium-sensitive (GCaMP signal)
%   * Blue channel: Calcium-insensitive (hemodynamic artifact)
% - For each ROI, calculate mean intensity across pixels
% - Determine which channel comes first (varies by trial)
% - Save three versions:
%   * Raw purple channel time series
%   * Raw blue channel time series  
%   * Corrected time series (blue subtracted from purple)
% - Apply 5-frame moving average smoothing to corrected data
%
% NORMALIZATION DETAILS:
% - For trial 1: Use frames 31-end to calculate baseline (skip first 30)
% - For other trials: Use frames 11-end (skip first 10)
% - This excludes initial settling period from baseline calculation
%
% OUTPUT FILES (in Matt_files/ subfolder):
% 
% For single-wavelength (control=0):
% - trialN.mat: 3D array [256×256×nFrames] of normalized fluorescence
%
% For dual-wavelength (control=1):
% - trialN_PURPLE.mat: Purple channel time series [nROIs×nTimepoints]
% - trialN_BLUE.mat: Blue channel time series [nROIs×nTimepoints]
% - trialN_Corrected.mat: Corrected time series (purple-blue) [nROIs×nTimepoints]
% - tc_all_brain_areas_CORRECTEDN.mat: Smoothed corrected data
%
% WHERE:
% - nROIs = 48 (number of brain regions)
% - nTimepoints = number of frames / 2 (since frames alternate between channels)
% =========================================================================

fprintf('STEP 3: Processing all trials and extracting time series...\n');
fprintf('-----------------------------------------------------------\n');

% Define the path to the green reference folder
green_path = fullfile(behav_path, 'green');

fprintf('Green reference path: %s\n', green_path);
fprintf('Processing mode: ');
if control == 0
    fprintf('Single-wavelength imaging\n');
else
    fprintf('Dual-wavelength with hemodynamic correction\n');
end
fprintf('\nProcessing trials (this may take several minutes)...\n');

try
    % Process all trials and get the number of trials processed
    num_of_trials = create_matt_files3(green_path, behav_path, control, plot_flag);
    
    fprintf('✓ All trials processed successfully\n');
    fprintf('  Total trials: %d\n', num_of_trials);
    fprintf('  Output files saved in: %s\\Matt_files\\\n\n', behav_path);
catch ME
    error('Error processing trials: %s\n', ME.message);
end

%% STEP 4: PROCESSING COMPLETE - SUMMARY
% =========================================================================
fprintf('=============================================================\n');
fprintf('PROCESSING PIPELINE COMPLETE!\n');
fprintf('=============================================================\n\n');

fprintf('SUMMARY OF OUTPUTS:\n');
fprintf('-----------------------------------------------------------\n');
fprintf('1. Green reference images:\n');
fprintf('   Location: %s\\green\\\n', behav_path);
fprintf('   Files: green_ds.mat, green.mat, Gs.mat\n\n');

fprintf('2. Brain ROI definitions:\n');
fprintf('   Location: %s\\green\\\n', behav_path);
fprintf('   Files: brain_ROIs.mat, pixels_to_remove.mat\n');
fprintf('   Number of ROIs: 48\n\n');

fprintf('3. Processed time series data:\n');
fprintf('   Location: %s\\Matt_files\\\n', behav_path);
fprintf('   Number of trials: %d\n', num_of_trials);

if control == 1
    fprintf('   Files per trial:\n');
    fprintf('     - trialN_PURPLE.mat (raw purple channel)\n');
    fprintf('     - trialN_BLUE.mat (raw blue channel)\n');
    fprintf('     - trialN_Corrected.mat (corrected signal)\n');
    fprintf('     - tc_all_brain_areas_CORRECTEDN.mat (smoothed)\n');
else
    fprintf('   Files per trial:\n');
    fprintf('     - trialN.mat (normalized fluorescence)\n');
end

fprintf('\n=============================================================\n');
fprintf('NEXT STEPS:\n');
fprintf('-----------------------------------------------------------\n');
fprintf('1. Load time series data for analysis:\n');
fprintf('   load(''%s\\Matt_files\\tc_all_brain_areas_CORRECTED1.mat'')\n\n', behav_path);

fprintf('2. Time series data format:\n');
fprintf('   - Dimensions: [48 ROIs × n timepoints]\n');
fprintf('   - Values: Normalized ΔF/F₀\n');
fprintf('   - Smoothing: 5-frame moving average\n\n');

fprintf('3. Access ROI information:\n');
fprintf('   load(''%s\\green\\brain_ROIs.mat'')\n', behav_path);
fprintf('   brain_ROIs(1).name  %% Get name of first ROI\n');
fprintf('   brain_ROIs(1).center  %% Get center coordinates\n\n');

fprintf('=============================================================\n');
% 
% DATA STRUCTURE DETAILS:
% -----------------------
% 
% 1. DCIMG File Format:
%    - Binary format from Hamamatsu cameras (C11440 or C13440)
%    - Contains header (232 or 1208 bytes) followed by uint16 pixel data
%    - Each frame is 512×512 pixels
%    - Files named with timestamp: 202XXXXX_XXXXXX.dcimg
%
% 2. Processing Parameters:
%    - Original resolution: 512×512 pixels
%    - Downsampled resolution: 256×256 pixels (ds=2)
%    - Frame rate: ~10 Hz (calculated from file size)
%    - Number of ROIs: 48 (4 rows × 12 columns)
%    - ROI radius: ~2 pixels (adjustable during ROI selection)
%
% 3. Memory Requirements:
%    - Each trial with 1000 frames: ~512 MB for single wavelength
%    - Dual wavelength: ~1 GB per trial
%    - Ensure sufficient RAM for your number of trials
%
% DATA QUALITY CHECKS:
% -------------------
% - Verify green reference images show clear fiber positions
% - Check that ROIs are well-aligned with fiber centers
% - Inspect time series for expected calcium transients
% - Look for photobleaching (gradual signal decay over time)
% - Verify blue/purple channels have similar noise levels (control=1)
%
% =========================================================================
