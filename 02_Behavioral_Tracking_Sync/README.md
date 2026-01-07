# Behavioral Tracking and Synchronization Pipeline

A MATLAB pipeline for synchronizing DeepLabCut behavioral tracking with calcium imaging acquisition. Processes video timestamps, filters arena boundaries, corrects tracking artifacts, and produces frame-aligned datasets for behavior-neural analysis.

---

## Requirements

**MATLAB Functions:**
- `Behavioral_Tracking_Pipeline.m` (main script)
- `extract_background_frame.m`
- `define_arena_boundary.m`
- `execute_ffmpeg_batch.m`
- `parse_video_timestamps.m`
- `detect_trial_onsets.m`
- `synchronize_tracking_imaging.m`
- `filter_arena_coordinates.m` (utility)
- `correct_tracking_outliers.m` (utility)

**External Software:**
- FFmpeg (timestamp extraction - batch file included in functions/)
- DeepLabCut (tracking CSV generation - run before this pipeline)

**Input Data Structure:**
```
data_path/
├── video.avi                    # Behavioral video
├── DLC_tracking.csv             # DeepLabCut output (see below)
├── trial1.dcimg                 # Imaging trial 1
├── trial2.dcimg                 # Imaging trial 2
└── processed/                   # Created by neuronal pipeline
    ├── trial_1_corrected.mat
    └── trial_2_corrected.mat
```

---

## DeepLabCut Integration

**DeepLabCut (DLC)** is an external pose estimation tool that must be run **before** this pipeline to generate frame-by-frame tracking coordinates.

**DLC Workflow (External):**
1. Label body parts on sample video frames
2. Train neural network for pose estimation  
3. Run inference on behavioral videos
4. Export tracking results as CSV

**Expected CSV Format:**
```csv
scorer,DLC_model,DLC_model,DLC_model,...
bodyparts,nose,nose,left_ear,left_ear,...
coords,x,y,likelihood,x,y,likelihood,...
0,245.3,189.2,0.98,248.1,192.5,0.95,...
1,246.1,190.3,0.97,249.0,193.2,0.96,...
```

The pipeline extracts X/Y pixel coordinates and computes the median across multiple body parts for robust tracking.

**DLC Resources:** https://deeplabcut.github.io/

---

## Pipeline Workflow

### Step 1: Extract Background Frame
**Function:** `extract_background_frame(data_path)`

Creates averaged background image by sampling 150 random frames.

**Output:**
- `background_frame.mat` - Average frame for visualization
- `video_dimensions.mat` - Video height and width

---

### Step 2: Define Arena Boundary
**Function:** `define_arena_boundary(data_path)`

Interactive polygon drawing to define valid tracking region.

**Process:**
1. Displays background frame
2. User clicks vertices along arena perimeter
3. Double-click to complete polygon

**Output:**
- `arena_polygon.mat` - Polygon ROI for filtering

---

### Step 3: Extract Video Timestamps
**Functions:** `execute_ffmpeg_batch()`, `parse_video_timestamps()`

Extracts precise frame timestamps using FFmpeg.

**Process:**
1. Executes FFmpeg batch file (included in functions/ folder)
2. Parses timestamp output into MATLAB array

**Output:**
- `processed/video_timestamps.mat` - Frame timestamps (seconds)

---

### Step 4: Detect Trial Onsets
**Function:** `detect_trial_onsets(data_path)`

Identifies trial start frames via LED indicator analysis.

**Process:**
1. User draws circle around LED indicator
2. Detects first trial via change point analysis
3. Calculates subsequent trials (300s intervals)
4. User verifies each trial (±20s window)

**Output:**
- `processed/trial_starts.mat` - Trial start frame indices

---

### Step 5: Synchronize Tracking and Imaging
**Function:** `synchronize_tracking_imaging(data_path)`

Aligns DLC tracking coordinates with calcium imaging frames.

**Process:**
1. Loads DLC tracking CSV, extracts median X/Y coordinates
2. Filters points outside arena boundaries (→ NaN)
3. Maps 10Hz imaging frames to ~20Hz video frames
4. Flags frames with >20ms temporal mismatch
5. Interpolates NaN gaps linearly
6. Corrects outliers (15-frame moving window, 15-pixel threshold)
7. Concatenates all trials into continuous dataset

**Output:**
- `processed/synchronized_tracking.mat`
  - `x_position_aligned` - X coordinates (pixels)
  - `y_position_aligned` - Y coordinates (pixels)
- `processed/imaging_data_aligned.mat` - Concatenated imaging data
- `processed/frame_alignment_indices.mat` - Frame mapping
- `processed/interpolation_markers.mat` - NaN markers

---

## Usage

```matlab
% Set data path
data_path = 'C:\Path\To\Your\Data\Folder';

% Run complete pipeline
Behavioral_Tracking_Pipeline
```

The pipeline will:
1. Extract background frame
2. Define arena boundary (interactive)
3. Extract timestamps via FFmpeg
4. Detect trial starts with LED analysis
5. Synchronize tracking with imaging

---

## Output Structure

```
data_path/
├── background_frame.mat
├── video_dimensions.mat
├── arena_polygon.mat
└── processed/
    ├── video_timestamps.mat
    ├── trial_starts.mat
    ├── synchronized_tracking.mat
    ├── imaging_data_aligned.mat
    ├── frame_alignment_indices.mat
    └── interpolation_markers.mat
```

**Data Format:**
- Tracking: `1 × N` arrays (N = total imaging frames)
- Imaging: `M × N` matrix (M = ROIs, N = frames)
- Signals: Normalized ΔF/F₀ with hemodynamic correction

---

## Quality Control

**Console Output Metrics:**
```
=== ARENA FILTERING ===
Points outside arena: 127 (1.1%)

=== TEMPORAL ALIGNMENT ===
Frames with >20ms mismatch: 15 (2.5%)
```

**Warning Thresholds:**
- Arena filtering >20% → Redraw polygon
- Poor alignment >10% → Check video quality

---

## Citation

```bibtex
@software{behavioral_pipeline,
  author = {[Your Name]},
  title = {Behavioral Tracking and Synchronization Pipeline},
  year = {2025},
  url = {https://github.com/[username]/behavioral-pipeline}
}
```

---

## License

[Specify License]
