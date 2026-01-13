# Fiber Photometry Calcium Imaging Preprocessing Pipeline

A MATLAB pipeline for processing dual-wavelength fiber photometry data with automated hemodynamic correction. This pipeline extracts calcium signals from 48 simultaneous recording sites arranged in a 4×12 fiber array.

## Overview

This pipeline processes raw calcium imaging data from fiber photometry experiments, separating calcium-dependent signals (GCaMP fluorescence) from hemodynamic artifacts using dual-wavelength imaging. The system simultaneously records from 48 brain regions, enabling large-scale neural activity mapping.

**Key Features:**
- Dual-wavelength hemodynamic correction (purple/blue channels)
- Automated ROI interpolation from corner landmarks
- Batch processing of multiple trials
- ΔF/F₀ normalization with baseline correction
- Signal smoothing with moving average filter

## Requirements

**MATLAB Functions:**
- `Neuronal_Preprocessing_Pipeline.m` (main script)
- `extract_reference_image.m`
- `define_recording_sites.m`
- `select_recording_site_rois.m`
- `extract_calcium_signals.m`
- `read_dcam_file.m`
- `adjust_brightness.m`

**Input Data:**
- Raw DCAM files (`.dcimg` format) from Hamamatsu cameras (C11440/C13440)
- Files should be named with format: `202*.dcimg`
- Image dimensions: 512×512 pixels

## Pipeline Workflow

### Step 1: Extract Reference Image

Creates reference images from the first recording to visualize fiber array layout.

**Process:**
- Reads first 2 frames from initial DCAM file
- Generates full-resolution (512×512) and downsampled (256×256) references
- Downsampled version optimizes interactive ROI selection speed

**Output:**
- `reference_image_full.mat` - High-resolution reference
- `reference_image_downsampled.mat` - Downsampled for ROI placement
- `raw_frames.mat` - Original frames for quality inspection

**Significance:** Provides spatial template for accurate ROI positioning over individual fiber locations.


### Step 2: Define Recording Sites

Interactive ROI definition for all 48 recording sites with semi-automated grid alignment.

**Process:**
1. User draws rectangular boundary around fiber array chamber
2. User adjusts 8 corner ROIs (sites 1, 12, 13, 24, 25, 36, 37, 48) to match fiber positions
3. Pipeline automatically interpolates positions for 40 intermediate ROIs
4. Linear interpolation ensures regular grid aligned with corner landmarks
5. Each ROI defined by center coordinates, radius, and binary pixel mask

**Recording Site Layout:**
```
Row 1: S1BF, CPU, S1BF, x, GP, x, x, x, x, M1, Re, Re
Row 2: BLA, BLA, S1BF, CeM, RT, S1BF, VPM, CA3, CA3, CA1, DG, Re
Row 3: x, PRh, DLEnt, DIEnt, DIEnt, DIEnt, DG, Ment, DG, Post, x, RSD
Row 4: x, DLEnt, Ment, TEA, CEnt, CEnt, V1, Prs, Post, x, RSD, x
```

*Brain region abbreviations: S1BF (Primary Somatosensory Cortex), BLA (Basolateral Amygdala), CA1/CA3 (Hippocampus), DG (Dentate Gyrus), M1 (Motor Cortex), Re (Nucleus Reuniens), and others.*

**Output:**
- `recording_sites.mat` - Structure array with 48 ROI definitions
- `chamber_mask.mat` - Binary mask excluding pixels outside recording area

**Significance:** Semi-automated approach balances precision (manual corner adjustment) with efficiency (automated interpolation), ensuring consistent ROI placement across experiments.

---
<img width="1986" height="950" alt="image" src="https://github.com/user-attachments/assets/f7886cae-d736-4553-86a8-6f06ef948d2a" />
<img width="1808" height="1212" alt="image" src="https://github.com/user-attachments/assets/c0e5934d-1fd2-4492-8a7d-32455296200a" />


---

### Step 3: Extract Calcium Signals

Processes all trials with dual-wavelength hemodynamic correction and signal normalization.

**Process:**

1. **Frame Extraction**
   - Reads all frames from DCAM files
   - Applies chamber mask to exclude background pixels
   - Downsamples to 256×256 for computational efficiency

2. **Channel Separation**
   - Alternating frames separated into purple (GCaMP, calcium-sensitive) and blue (hemodynamic reference) channels
   - Channel assignment determined automatically based on relative brightness

3. **Signal Extraction**
   - Mean intensity calculated per ROI per timepoint
   - Averages all pixels within each circular ROI

4. **Normalization (ΔF/F₀)**
   - Baseline (F₀) = median intensity after initial settling period
   - Skip first 30 frames (trial 1) or 10 frames (subsequent trials)
   - Formula: `ΔF/F = (F - F₀) / F₀`

5. **Hemodynamic Correction**
   - Corrected signal = Blue channel - Purple channel
   - Removes motion artifacts, blood volume changes, and other non-calcium-dependent signals

6. **Signal Smoothing**
   - 5-frame moving average filter reduces high-frequency noise
   - Preserves biologically relevant temporal dynamics

**Output (per trial N):**
- `trial_N_purple.mat` - Calcium-sensitive channel [48 sites × timepoints]
- `trial_N_blue.mat` - Hemodynamic reference channel [48 sites × timepoints]
- `trial_N_corrected.mat` - Hemodynamically corrected signals
- `trial_N_corrected_smoothed.mat` - Final output with noise reduction

**Significance:** Dual-wavelength correction is critical for isolating true neural activity from confounding hemodynamic signals that can dominate raw fluorescence measurements.

---

<img width="2874" height="1638" alt="image" src="https://github.com/user-attachments/assets/ffcd791b-f4b5-4b4d-92f4-cf9f8b040bac" />

---

## Usage

```matlab
% Set path to data folder containing DCAM files
data_path = 'C:\Path\To\Your\Data\Folder';

% Run complete pipeline
Neuronal_Preprocessing_Pipeline
```

The pipeline will:
1. Extract reference images automatically
2. Open interactive ROI selection interface (adjust 8 corners, press Enter when done)
3. Process all trials with progress indicators
4. Save organized output files

## Output Structure

```
data_folder/
├── reference/
│   ├── reference_image_full.mat
│   ├── reference_image_downsampled.mat
│   ├── raw_frames.mat
│   ├── recording_sites.mat
│   └── chamber_mask.mat
└── processed/
    ├── trial_1_purple.mat
    ├── trial_1_blue.mat
    ├── trial_1_corrected.mat
    ├── trial_1_corrected_smoothed.mat
    ├── trial_2_purple.mat
    └── ...
```

## Signal Processing Details

**Data Format:** All output matrices are `[48 recording sites × timepoints]`

**Signal Type:** Normalized ΔF/F₀ with hemodynamic correction

**Temporal Resolution:** Determined by camera frame rate (typically 10-20 Hz per channel)

**Spatial Resolution:** ~2-5 pixel radius per ROI (adjustable during ROI definition)

## Customization

**Parameters (in `Neuronal_Preprocessing_Pipeline.m`):**
- `params.dual_wavelength` - Enable dual-wavelength correction (default: `true`)
- `params.show_plots` - Display time series plots during processing (default: `false`)

**Camera Compatibility:**
- Default: Hamamatsu C13440 (1208-byte header)
- For C11440: Modify header size in `read_dcam_file.m` (line 49)

**ROI Parameters:**
- Initial ROI radius: 2 pixels (adjustable in `select_recording_site_rois.m`, line 34)
- Grid dimensions: 4 rows × 12 columns (modify `num_sites` and `region_names` to customize)

## Technical Notes

**Dual-Wavelength Imaging:**
The pipeline uses interleaved purple (~405nm excitation) and blue (~470nm excitation) illumination. Purple light excites GCaMP (calcium-sensitive), while blue light provides a calcium-insensitive reference that captures hemodynamic changes. Subtracting blue from purple isolates calcium-dependent signals.

**Baseline Calculation:**
Median is used instead of mean to provide robust baseline estimation resistant to transient activity during the baseline period.

**Chamber Masking:**
Excluding pixels outside the recording chamber prevents edge artifacts and background noise from contaminating ROI signals.

## Citation

```bibtex
@software{behavioral_pipeline,
  author = {[Zvi Kuhr]},
  title = {Behavioral Tracking and Synchronization Pipeline},
  year = {2025},
  url = {https://github.com/zvikuhr1-coder/behavioral-pipeline}
}
```

