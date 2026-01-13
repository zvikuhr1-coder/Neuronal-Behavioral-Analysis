%% NEURONAL TRACE QUALITY CONTROL SYSTEM - MAIN SCRIPT
% =========================================================================
% Purpose: Interactive quality control for dual-wavelength fiber photometry data
% 
% This script processes neuronal calcium imaging data recorded with two laser
% wavelengths (blue and purple). The blue channel captures calcium-dependent
% signals while purple captures isosbestic/motion artifacts. The subtracted
% signal (blue - purple) represents the cleaned neuronal activity.
%
% DEMO MODE:
% Set DEMO_MODE = true to generate synthetic data and test the workflow
% without requiring actual recording files.
%
% REAL DATA MODE:
% Set DEMO_MODE = false and configure paths to your actual data directories.
%
% Author: [Your Name]
% Last Modified: [Date]
% =========================================================================

clear; clc;

%% ========================================================================
% CONFIGURATION SECTION
% ========================================================================

% --- Brain Region Identifiers ---
% List of all 37 brain regions recorded across sessions
ID = {'S1BF','CPU','S1BF(2)','GP','M1','Re','Re(2)',...
   'BLA','BLA(2)','S1BF(3)','CeM','RT','S1BF(4)','VPM','CA3','CA3(2)','CA1','DG','Re(3)',...
   'PRh','DLEnt','DIEnt','VIEnt','VIEnt(2)','DG(2)','Ment','DG(3)','Post','RSD',...
   'DLEnt(2)','Ment(2)','TEA','CEnt','CEnt(2)','V1','Prs','Post(2)'};

% --- DEMO MODE TOGGLE ---
% Set to true to run with synthetic demonstration data
DEMO_MODE = true;

%% ========================================================================
% DATA SOURCE CONFIGURATION
% ========================================================================

if DEMO_MODE
    fprintf('╔════════════════════════════════════════════════════╗\n');
    fprintf('║          RUNNING IN DEMO MODE                      ║\n');
    fprintf('╚════════════════════════════════════════════════════╝\n');
    fprintf('Creating synthetic calcium imaging data...\n');
    fprintf('This will generate realistic fiber photometry recordings\n');
    fprintf('with typical calcium transients and various artifacts.\n\n');
    
    % Demo parameters
    DEMO_NUM_BRAIN_REGIONS = 37;     % Number of brain regions
    DEMO_NUM_SESSIONS = 10;          % Number of recording sessions
    DEMO_FRAMES_PER_TRIAL = 600;     % Frames per trial (600 frames)
    DEMO_TRIALS_PER_SESSION = 10;    % Trials per session (total: 6000 frames/session)
    DEMO_MOUSE_NAME = 'DEMO_MOUSE';  % Mouse identifier
    
    % Generate demo data structure
    [paths, MICE] = create_demo_data_structure(...
        DEMO_MOUSE_NAME, ...
        DEMO_NUM_SESSIONS, ...
        DEMO_NUM_BRAIN_REGIONS, ...
        DEMO_TRIALS_PER_SESSION, ...
        DEMO_FRAMES_PER_TRIAL, ...
        ID);
    
    fprintf('\n✓ Demo data created successfully\n');
    fprintf('  Mouse: %s\n', DEMO_MOUSE_NAME);
    fprintf('  Sessions: %d\n', DEMO_NUM_SESSIONS);
    fprintf('  Brain regions: %d\n', DEMO_NUM_BRAIN_REGIONS);
    fprintf('  Total frames per session: %d\n', DEMO_TRIALS_PER_SESSION * DEMO_FRAMES_PER_TRIAL);
    fprintf('  Trials per session: %d\n', DEMO_TRIALS_PER_SESSION);
    fprintf('  Frames per trial: %d\n\n', DEMO_FRAMES_PER_TRIAL);
    
else
    % --- REAL DATA CONFIGURATION ---
    fprintf('╔════════════════════════════════════════════════════╗\n');
    fprintf('║          RUNNING WITH REAL DATA                    ║\n');
    fprintf('╚════════════════════════════════════════════════════╝\n\n');
    
    % Define paths to recording sessions
    % Each path should contain a 'Matt_files' subdirectory with:
    %   - tc_all_brain_areas_CORRECTED1.mat (neuronal traces)
    %   - trial#_BLUE.mat (blue laser signal for each trial)
    %   - trial#_PURPLE.mat (purple laser signal for each trial)
    paths = {
        'D:\AD_6\AD21\21_1L1R\TEST',...
        'D:\AD_6\AD21\21_2L\TEST',...
        'D:\AD_6\AD26\26_1L1R\TEST',...
        'D:\AD_6\AD26\26_2L\TEST',...
        'D:\AD_6\AD26\26_2R\TEST',...
    };
    
    % Define mouse identifiers (should match directory names in paths)
    MICE = {'21_1L1R','21_2L','26_2R','26_1L1R','26_2L'};
    
    % Alternative mouse identifier examples:
    % MICE = {'YELLOW','RED','GREEN','BLUE'};
    % MICE = {'C3','C4_BLACK','C4_RED','C5_BLACK','C5_BLUE','C5_RED'};
end

%% ========================================================================
% PHASE 1: BUILD MOUSE-SPECIFIC BASELINE STATISTICS
% ========================================================================
% Aggregate data across all sessions for each mouse to establish baseline
% signal characteristics. These statistics are used for artifact detection
% in Phase 2.
% ========================================================================

fprintf('╔════════════════════════════════════════════════════╗\n');
fprintf('║  PHASE 1: Building Mouse-Specific Statistics      ║\n');
fprintf('╚════════════════════════════════════════════════════╝\n\n');

% Initialize structure to hold aggregated data for each mouse
MOUSE_DATA = struct();

% Loop through each mouse
for j = 1:length(MICE)
    mouse_name = MICE{j};
    fprintf('→ Processing mouse: %s\n', mouse_name);
    
    % Initialize arrays to accumulate data across all sessions for this mouse
    mouse_frames = [];    % Neuronal traces (blue - purple)
    mouse_blue = [];      % Raw blue laser signal
    mouse_purple = [];    % Raw purple laser signal
    
    % Loop through all session paths to find sessions belonging to this mouse
    for z = 1:length(paths)
        % Parse path to check if it belongs to current mouse
        pathParts = strsplit(paths{z}, filesep);
        brain_path = fullfile(paths{z}, 'Matt_files');
        
        % Check if this session belongs to the current mouse
        if any(ismember(mouse_name, pathParts))
            if exist(brain_path, 'dir')
                cd(brain_path);
                
                % Look for corrected neuronal traces file
                if exist('tc_all_brain_areas_CORRECTED1.mat', 'file')
                    % Load neuronal traces (blue - purple subtracted)
                    load('tc_all_brain_areas_CORRECTED1.mat', 'tc_all_brain_areas_CORRECTED')
                    
                    % Count trials in this session
                    cd(paths{z})
                    list = dir(['202' '*.dcimg']);
                    num_of_trials = length(list);
                    cd(brain_path)
                    
                    % Load raw laser signals for all trials in this session
                    all_blue = [];
                    all_purple = [];
                    
                    for i = 1:num_of_trials
                        blue_file = sprintf('trial%d_BLUE.mat', i);
                        purple_file = sprintf('trial%d_PURPLE.mat', i);
                        
                        if exist(blue_file, 'file') && exist(purple_file, 'file')
                            % Load trial data
                            blue_struct = load(blue_file);
                            purple_struct = load(purple_file);

                            % Get field names (variable names may differ per trial)
                            blue_varname = fieldnames(blue_struct);
                            purple_varname = fieldnames(purple_struct);

                            % Extract actual data
                            blue = blue_struct.(blue_varname{1});
                            purple = purple_struct.(purple_varname{1});
                            
                            % Accumulate across trials
                            all_purple = [all_purple, purple];
                            all_blue = [all_blue, blue];
                        end
                    end
                    
                    % Accumulate across sessions
                    mouse_frames = [mouse_frames, tc_all_brain_areas_CORRECTED];
                    mouse_blue = [mouse_blue, all_blue];
                    mouse_purple = [mouse_purple, all_purple];
                end
            end
        end
    end
    
    % Store accumulated data for this mouse
    % Convert mouse name to valid MATLAB structure field name
    validName = matlab.lang.makeValidName(mouse_name);
    MOUSE_DATA.(validName).frames = mouse_frames;
    MOUSE_DATA.(validName).blue = mouse_blue;
    MOUSE_DATA.(validName).purple = mouse_purple;
    
    fprintf('  ✓ Collected %d total frames for %s\n', size(mouse_frames, 2), mouse_name);
end

fprintf('\n✓ MOUSE_DATA structure built successfully\n');
fprintf('  Ready for baseline statistics calculation\n\n');

%% ========================================================================
% OPTIONAL: NORMALIZE TO GRAND MEDIAN
% ========================================================================
% Uncomment to adjust traces to center around a grand median across sessions
% This can help with cross-session comparisons
% 
% normalize_neuronal_data_to_grand_median(MOUSE_DATA, paths, MICE, 600);

%% ========================================================================
% PHASE 2: INTERACTIVE ARTIFACT CORRECTION
% ========================================================================
% Process each session individually with interactive artifact detection
% and correction. Users review detected artifacts and choose correction
% strategies.
% ========================================================================

fprintf('╔════════════════════════════════════════════════════╗\n');
fprintf('║  PHASE 2: Interactive Artifact Correction         ║\n');
fprintf('╚════════════════════════════════════════════════════╝\n\n');

% Processing parameters
SMOOTHING_WINDOW = 5;  % Window size for moving average smoothing
BASELINE_OFFSET = 1;   % Offset for baseline normalization (centers around 0)

% Loop through each mouse
for j = 1:length(MICE)
    mouse_name = MICE{j};
    fprintf('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    fprintf('Processing sessions for mouse: %s\n', mouse_name);
    fprintf('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    
    % Loop through all sessions for this mouse
    for z = 1:length(paths)
        pathParts = strsplit(paths{z}, filesep);
        brain_path = fullfile(paths{z}, 'Matt_files');
        
        % Check if this session belongs to current mouse
        if any(ismember(mouse_name, pathParts))
            if exist(brain_path, 'dir')
                cd(brain_path);
                
                % Check for input file
                if exist('tc_all_brain_areas_CORRECTED1.mat', 'file')
                    fprintf('\n→ Processing session: %s\n', brain_path);
                    
                    % Load neuronal traces
                    load('tc_all_brain_areas_CORRECTED1.mat', 'tc_all_brain_areas_CORRECTED')
                    
                    % Get trial information
                    cd(paths{z})
                    list = dir(['202' '*.dcimg']);
                    num_of_trials = length(list);
                    cd(brain_path)
                    
                    % Collect and preprocess all trials for this session
                    session_blue = [];
                    session_purple = [];
                    
                    for i = 1:num_of_trials
                        blue_file = sprintf('trial%d_BLUE.mat', i);
                        purple_file = sprintf('trial%d_PURPLE.mat', i);
                        
                        if exist(blue_file, 'file') && exist(purple_file, 'file')
                            % Load trial data
                            blue_struct = load(blue_file);
                            purple_struct = load(purple_file);

                            % Extract data
                            blue_varname = fieldnames(blue_struct);
                            purple_varname = fieldnames(purple_struct);

                            blue = blue_struct.(blue_varname{1});
                            purple = purple_struct.(purple_varname{1});
                            
                            % Smooth and baseline-correct signals
                            % - Apply moving average smoothing (5-frame window)
                            % - Subtract 1 to center around 0
                            blue = smoothdata(blue(:,:), 2, 'movmean', SMOOTHING_WINDOW) - BASELINE_OFFSET;
                            purple = smoothdata(purple(:,:), 2, 'movmean', SMOOTHING_WINDOW) - BASELINE_OFFSET;
                            
                            % Concatenate across trials
                            session_purple = [session_purple, purple];
                            session_blue = [session_blue, blue];
                        end
                    end
                    
                    % Apply interactive artifact correction to this session
                    if ~isempty(session_blue) && ~isempty(session_purple)
                        fprintf('  Starting interactive artifact correction (%d trials)\n', num_of_trials);
                        
                        % Call artifact correction system (unchanged function)
                        [tc_artifact_corrected] = artifact_correction_system3(...
                            session_blue, ...
                            session_purple, ...
                            tc_all_brain_areas_CORRECTED, ...
                            MOUSE_DATA, ...
                            mouse_name);
                        
                        % Save corrected data for this session
                        save('tc_artifact_corrected.mat', 'tc_artifact_corrected');
                        fprintf('  ✓ Corrected data saved: tc_artifact_corrected.mat\n');
                        
                    else
                        fprintf('  ⚠ Warning: No laser data found for this session\n');
                    end
                end
            end
        end
    end
end

fprintf('\n╔════════════════════════════════════════════════════╗\n');
fprintf('║  All Sessions Processed Successfully              ║\n');
fprintf('╚════════════════════════════════════════════════════╝\n');

% Optional: Close all figures
% delete(findall(0, 'Type', 'figure'));

%% ========================================================================
% DEMO DATA GENERATION FUNCTIONS
% ========================================================================

function [session_paths, mouse_ids] = create_demo_data_structure(...
    mouse_name, num_sessions, num_regions, trials_per_session, frames_per_trial, brain_regions)
% Create complete synthetic data structure for demo mode
%
% Generates:
% - Directory structure matching real data format
% - Neuronal traces with realistic calcium dynamics
% - Blue and purple laser signals with artifacts
% - Trial files (.mat) and dummy imaging files (.dcimg)

    % Create base directory for demo data
    demo_base_dir = fullfile(tempdir, 'neuronal_qc_demo');
    if exist(demo_base_dir, 'dir')
        rmdir(demo_base_dir, 's');  % Remove old demo data
    end
    mkdir(demo_base_dir);
    
    session_paths = cell(1, num_sessions);
    mouse_ids = {mouse_name};
    
    fprintf('Generating demo data...\n');
    fprintf('  Base directory: %s\n', demo_base_dir);
    
    % Generate data for each session
    for session_idx = 1:num_sessions
        fprintf('  → Creating session %d/%d...', session_idx, num_sessions);
        
        % Create session directory structure
        session_name = sprintf('Session_%02d', session_idx);
        session_dir = fullfile(demo_base_dir, mouse_name, session_name);
        matt_files_dir = fullfile(session_dir, 'Matt_files');
        
        if ~exist(matt_files_dir, 'dir')
            mkdir(matt_files_dir);
        end
        
        session_paths{session_idx} = session_dir;
        
        % Generate neuronal traces for this session (all trials concatenated)
        total_frames = trials_per_session * frames_per_trial;
        tc_all_brain_areas_CORRECTED = generate_calcium_traces(...
            num_regions, total_frames, session_idx);
        
        % Save neuronal traces
        save(fullfile(matt_files_dir, 'tc_all_brain_areas_CORRECTED1.mat'), ...
            'tc_all_brain_areas_CORRECTED');
        
        % Generate trial-specific laser signals
        for trial_idx = 1:trials_per_session
            % Determine frame range for this trial
            frame_start = (trial_idx - 1) * frames_per_trial + 1;
            frame_end = trial_idx * frames_per_trial;
            
            % Extract traces for this trial
            trial_traces = tc_all_brain_areas_CORRECTED(:, frame_start:frame_end);
            
            % Generate blue and purple signals based on traces
            [trial_blue_data, trial_purple_data] = generate_laser_signals(...
                trial_traces, num_regions, frames_per_trial, session_idx, trial_idx);
            
            % Save with dynamic variable names (as required by loading code)
            blue_varname = sprintf('trial%d_blue', trial_idx);
            purple_varname = sprintf('trial%d_purple', trial_idx);
            
            % Create structs with dynamic field names
            blue_struct = struct();
            blue_struct.(blue_varname) = trial_blue_data;
            
            purple_struct = struct();
            purple_struct.(purple_varname) = trial_purple_data;
            
            % Save trial files
            save(fullfile(matt_files_dir, sprintf('trial%d_BLUE.mat', trial_idx)), ...
                '-struct', 'blue_struct');
            save(fullfile(matt_files_dir, sprintf('trial%d_PURPLE.mat', trial_idx)), ...
                '-struct', 'purple_struct');
            
            % Create dummy .dcimg file for trial counting
            dummy_file = fullfile(session_dir, ...
                sprintf('202401%02d_trial%d.dcimg', session_idx, trial_idx));
            fid = fopen(dummy_file, 'w');
            fclose(fid);
        end
        
        fprintf(' Done\n');
    end
end

function calcium_traces = generate_calcium_traces(num_regions, num_frames, session_seed)
% Generate realistic calcium imaging traces with typical dynamics
%
% Features:
% - Baseline drift (slow fluctuations)
% - Calcium transients (event-like increases)
% - Gaussian noise
% - Occasional artifacts (extreme outliers)
% - Values typically in range ±0.05 as specified

    % Set random seed for reproducibility within session
    rng(session_seed * 100);
    
    calcium_traces = zeros(num_regions, num_frames);
    
    for region_idx = 1:num_regions
        % Initialize signal components
        time = (1:num_frames)';
        
        % === Component 1: Slow baseline drift ===
        % Simulates photobleaching and other slow changes
        drift_frequency = 1 / (num_frames / 2);  % One cycle per half session
        drift_amplitude = 0.01;  % Small drift
        drift = drift_amplitude * sin(2*pi*drift_frequency*time);
        
        % === Component 2: Calcium transients ===
        % Simulate neural activity events
        transients = zeros(num_frames, 1);
        
        % Random number of events per region (10-30 events per session)
        num_events = randi([10, 30]);
        
        % Random event positions (avoid edges)
        event_positions = sort(randperm(num_frames - 200, num_events) + 100);
        
        for event_idx = 1:num_events
            pos = event_positions(event_idx);
            
            % Calcium transient parameters (realistic values)
            amplitude = 0.02 + rand() * 0.03;      % Peak amplitude 0.02-0.05
            tau_rise = 5 + rand() * 10;            % Rise time: 5-15 frames
            tau_decay = 30 + rand() * 50;          % Decay time: 30-80 frames
            
            % Generate double exponential transient
            event_window = max(1, pos-20):min(num_frames, pos+150);
            t_event = event_window - pos;
            
            % Double exponential: (1 - exp(-t/tau_rise)) * exp(-t/tau_decay)
            event_shape = amplitude * ...
                (1 - exp(-t_event/tau_rise)) .* exp(-t_event/tau_decay);
            event_shape(t_event < 0) = 0;
            
            transients(event_window) = transients(event_window) + event_shape';
        end
        
        % === Component 3: Gaussian noise ===
        % Typical photon shot noise
        noise_amplitude = 0.005;  % Small noise
        noise = noise_amplitude * randn(num_frames, 1);
        
        % === Component 4: Occasional artifacts ===
        % 20% chance of artifact per region
        artifact_component = zeros(num_frames, 1);
        
        if rand() < 0.2
            % Random artifact position
            artifact_pos = randi([200, num_frames-200]);
            artifact_length = randi([5, 40]);  % 5-40 frames
            artifact_end = min(num_frames, artifact_pos + artifact_length);
            
            % Artifact type (spike or drift)
            if rand() < 0.5
                % Sudden spike artifact (motion artifact)
                artifact_amplitude = 0.1 + rand() * 0.2;  % Large deviation
                artifact_component(artifact_pos:artifact_end) = ...
                    artifact_amplitude * (1 + 0.3*randn(artifact_end-artifact_pos+1, 1));
            else
                % Gradual drift artifact (photobleaching step)
                artifact_amplitude = 0.05 + rand() * 0.1;
                artifact_component(artifact_pos:end) = artifact_amplitude;
            end
        end
        
        % === Combine all components ===
        signal = drift + transients + noise + artifact_component;
        
        % Store in output array
        calcium_traces(region_idx, :) = signal;
    end
end

function [blue_signal, purple_signal] = generate_laser_signals(...
    calcium_traces, num_regions, num_frames, session_seed, trial_seed)
% Generate blue and purple laser signals from calcium traces
%
% Blue signal = calcium + motion + noise (baseline ~1.0)
% Purple signal = motion + noise (baseline ~1.0, no calcium)
% 
% The difference (blue - purple) should approximately recover calcium_traces

    % Set random seed
    rng(session_seed * 1000 + trial_seed);
    
    blue_signal = ones(num_regions, num_frames);
    purple_signal = ones(num_regions, num_frames);
    
    for region_idx = 1:num_regions
        % Get calcium trace for this region
        calcium = calcium_traces(region_idx, :);
        
        % === Generate motion artifact (present in both channels) ===
        % Simulate slow movement artifacts
        time = (1:num_frames)';
        motion_frequency = 1 / (num_frames / 3);
        motion_amplitude = 0.03 + rand() * 0.02;  % 0.03-0.05
        motion = motion_amplitude * sin(2*pi*motion_frequency*time + rand()*2*pi);
        
        % Add high-frequency motion jitter
        motion_jitter = 0.01 * randn(num_frames, 1);
        motion = motion' + motion_jitter';
        
        % === Generate blue signal ===
        % Blue = baseline + calcium + motion + noise
        blue_baseline = 1.0 + 0.02 * randn();  % Slight baseline variation
        blue_noise = 0.01 * randn(1, num_frames);
        
        blue_signal(region_idx, :) = blue_baseline + calcium + motion + blue_noise;
        
        % === Generate purple signal ===
        % Purple = baseline + motion + noise (no calcium)
        purple_baseline = 1.0 + 0.02 * randn();
        purple_noise = 0.01 * randn(1, num_frames);
        
        % Purple typically has slightly less signal than blue
        purple_motion_scale = 0.8 + rand() * 0.3;  % 0.8-1.1 of motion
        purple_signal(region_idx, :) = purple_baseline + ...
            purple_motion_scale * motion + purple_noise;
        
        % === Add channel-specific artifacts (occasionally) ===
        % 10% chance of channel swap artifact (purple larger than blue)
        if rand() < 0.1
            % Swap signals in a region to create inconsistency
            temp = blue_signal(region_idx, :);
            blue_signal(region_idx, :) = purple_signal(region_idx, :);
            purple_signal(region_idx, :) = temp;
        end
        
        % 10% chance of extreme spike in one channel
        if rand() < 0.1
            spike_pos = randi([100, num_frames-100]);
            spike_length = randi([3, 20]);
            spike_end = min(num_frames, spike_pos + spike_length);
            spike_amplitude = 0.5 + rand() * 1.0;
            
            if rand() < 0.5
                % Blue spike
                blue_signal(region_idx, spike_pos:spike_end) = ...
                    blue_signal(region_idx, spike_pos:spike_end) + spike_amplitude;
            else
                % Purple spike
                purple_signal(region_idx, spike_pos:spike_end) = ...
                    purple_signal(region_idx, spike_pos:spike_end) + spike_amplitude;
            end
        end
    end
end