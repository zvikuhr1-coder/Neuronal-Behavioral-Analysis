function batch_file_handler(target_path, source_batch_file)
% BATCH_FILE_HANDLER Copy and execute FFmpeg batch file for timestamp extraction
%
% Syntax:
%   batch_file_handler(target_path)
%   batch_file_handler(target_path, source_batch_file)
%
% Description:
%   Copies a batch file (typically containing FFmpeg commands) to a target
%   directory and executes it. Used primarily for extracting frame timestamps
%   from video files. Includes safety checks to prevent overwriting existing
%   batch files and provides detailed error reporting.
%
% Inputs:
%   target_path - String specifying destination directory for batch file
%   source_batch_file - (Optional) String path to source batch file
%                       Default: 'K:\extract_timestamps.bat'
%
% Outputs:
%   None (batch file executed in target directory, results written to disk)
%
% Behavior:
%   - Validates source and target paths exist
%   - Checks if batch file already present in target (exits if found)
%   - Copies batch file to target directory
%   - Executes batch file from target directory
%   - Returns to original directory after execution
%   - Reports execution status and any errors
%
% Example:
%   % Use default batch file location
%   batch_file_handler('D:\AD_6\AD21\1L1R\TEST');
%   
%   % Specify custom batch file
%   batch_file_handler('D:\AD_6\AD21\1L1R\TEST', 'C:\Scripts\custom_extract.bat');
%
% Notes:
%   - Default batch file typically contains FFmpeg commands like:
%     ffprobe -select_streams v:0 -show_entries frame=pts_time -of csv video.avi
%   - Function terminates without error if batch file exists in target
%   - Always returns to original directory, even if execution fails
%
% See also: system, copyfile, fileparts

% Set default batch file if not provided
if nargin < 2
    source_batch_file = 'K:\extract_timestamps.bat';
end

% Validate source batch file exists
if ~exist(source_batch_file, 'file')
    error('Source batch file %s does not exist!', source_batch_file);
end

% Extract batch file name from full path
[~, batch_name, batch_ext] = fileparts(source_batch_file);
batch_filename = [batch_name, batch_ext];

% Construct destination path
dest_batch_file = fullfile(target_path, batch_filename);

% Validate target directory exists
if ~exist(target_path, 'dir')
    error('Target path %s does not exist!', target_path);
end

% Check if batch file already present (avoid overwriting)
if exist(dest_batch_file, 'file')
    fprintf('Batch file already exists in target directory: %s\n', dest_batch_file);
    fprintf('Skipping batch file copy and execution.\n');
    return;
end

% Copy batch file to target directory
try
    copyfile(source_batch_file, dest_batch_file);
    fprintf('Copied batch file to: %s\n', target_path);
catch copy_error
    error('Failed to copy batch file to %s: %s', target_path, copy_error.message);
end

% Execute batch file in target directory
try
    % Store current directory for later restoration
    current_dir = pwd;
    
    % Change to target directory for execution
    cd(target_path);
    
    % Execute batch file and capture output
    [status, cmdout] = system(batch_filename);
    
    % Return to original directory
    cd(current_dir);
    
    % Report execution results
    if status == 0
        fprintf('Successfully executed batch file in: %s\n', target_path);
    else
        warning('Batch file returned non-zero status (%d) in: %s', status, target_path);
        fprintf('Command output:\n%s\n', cmdout);
    end
    
catch exec_error
    % Ensure directory restoration even on error
    cd(current_dir);
    error('Failed to execute batch file in %s: %s', target_path, exec_error.message);
end

end