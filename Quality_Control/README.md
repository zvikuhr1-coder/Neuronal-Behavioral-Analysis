# Neuronal Trace Quality Control Pipeline

## Overview
This pipeline provides interactive quality control for dual-wavelength fiber photometry data acquired from multiple brain regions. It detects and corrects motion artifacts, photobleaching, and channel inconsistencies in calcium imaging recordings through an intuitive graphical interface with mouse-specific statistical validation.

## Key Features
* **Demo Mode:** Generate synthetic calcium imaging data to test the workflow without experimental recordings
* **Dual-Wavelength Correction:** Processes blue (calcium-dependent) and purple (isosbestic) channels to isolate neuronal activity
* **Mouse-Specific Statistics:** Builds baseline signal characteristics across all sessions for each subject
* **Interactive Artifact Detection:** Visual identification of problematic traces with outlier flagging (±3 STD)
* **Channel Flip Correction:** Automated detection and correction of swapped recording channels
* **Flexible Correction Methods:** NaN replacement, linear interpolation, or single-channel substitution
* **Batch Processing:** Apply corrections to individual brain regions or all 37 regions simultaneously

---

## Pipeline Architecture

### Phase 1: Build Mouse-Specific Baseline Statistics
**Purpose:** Aggregate data across all recording sessions for each mouse to establish baseline signal characteristics used for artifact detection.

**Processing:**
1. Scans all session directories for each mouse identifier
2. Loads neuronal traces (`tc_all_brain_areas_CORRECTED1.mat`)
3. Loads raw blue and purple laser signals (`trial#_BLUE.mat`, `trial#_PURPLE.mat`)
4. Concatenates all sessions into mouse-specific data structure
5. Calculates per-region median and standard deviation

**Output:**
- `MOUSE_DATA` structure containing aggregated blue/purple/corrected signals for statistical validation

---

### Phase 2: Interactive Artifact Correction
**Function:** `artifact_correction_system3(session_blue, session_purple, session_frames, MOUSE_DATA, current_mouse_name)`

Processes each session individually with four interactive steps:

#### Step 1: Channel Flip Detection
Displays first 600 frames across all brain regions. User verifies whether blue-purple subtraction is correct or channels are swapped.

**Options:**
- **Traces Look Normal** → Keep original `corrected = blue - purple`
- **Traces Look Flipped** → Flip to `corrected = purple - blue`

---

#### Step 2: Trace Selection
Navigate through all frames using scroll wheel or buttons (±600 frame windows). Click on problematic traces to enter editing mode. Green statistical boundaries (±3 STD from mouse-specific median) highlight outliers.

**Navigation:**
- Scroll wheel: Move forward/backward through frames
- **← Previous 600 / Next 600 →** buttons
- Click on trace → Opens editing interface


---

#### Step 3: Trace Editing
Detailed view of selected brain region with blue/purple channels, statistical boundaries, and distribution histogram. Supports frame-range or full-trace corrections.

**Single Area Actions:**
- **Set Range to NaN** - Mark frames as invalid (excluded from analysis)
- **Use Blue for Range** - Replace with raw blue channel (removes subtraction)
- **Interpolate Range** - Linear interpolation between boundary points
- **Set Entire NaN** - Mark entire trace as invalid
- **Use Blue Entire** - Replace entire trace with blue channel

**Batch Operations (All 37 Areas):**
- **Batch NaN Range** - Apply NaN to same frame range across all regions
- **Batch Blue Range** - Replace frame range with blue channel for all regions
- **Batch Interpolate** - Interpolate frame range across all regions


---

#### Step 4: Review and Confirmation
Summary of all modifications with option to accept changes or return to selection.

**Output:**
- `tc_artifact_corrected.mat` - Corrected neuronal traces for the session

---

## Demo Mode

**Purpose:** Test the complete pipeline with synthetic data matching real experimental structure (37 brain regions, 10 sessions, 10 trials per session, 600 frames per trial).

**Activation:**
```matlab
% In Trace_QC_Pipeline.m, set:
DEMO_MODE = true;
```

**Generated Data:**
- Realistic calcium transients (double exponential dynamics, 0.02-0.05 peak amplitude)
- Slow baseline drift (photobleaching simulation)
- Motion artifacts (present in both channels)
- Occasional outliers (20% of regions, 0.1-0.3 amplitude spikes)
- Channel swap artifacts (10% probability)

**Demo Output:**
```
╔══════════════════════════════════════════════════╗
║          RUNNING IN DEMO MODE                    ║
╚══════════════════════════════════════════════════╝
Creating synthetic calcium imaging data...

✓ Demo data created successfully
  Mouse: DEMO_MOUSE
  Sessions: 10
  Brain regions: 37
  Total frames per session: 6000
  Trials per session: 10
  Frames per trial: 600
```

---

## Data Structure

### Real Data Mode Requirements
```
data_path/
├── TEST/
│   ├── 202*.dcimg                      # Trial video files (for counting)
│   └── Matt_files/
│       ├── tc_all_brain_areas_CORRECTED1.mat   # Neuronal traces (37×N)
│       ├── trial1_BLUE.mat                      # Blue channel trial 1
│       ├── trial1_PURPLE.mat                    # Purple channel trial 1
│       ├── trial2_BLUE.mat
│       ├── trial2_PURPLE.mat
│       └── ...
```

**Directory Naming Convention:**
```matlab
paths = {
    'D:\AD_6\AD21\21_1L1R\TEST',  % Mouse: 21_1L1R
    'D:\AD_6\AD21\21_2L\TEST',    % Mouse: 21_2L
    ...
};

MICE = {'21_1L1R', '21_2L', ...};  % Must match folder names
```

**Brain Region IDs:**
```matlab
ID = {'S1BF', 'CPU', 'S1BF(2)', 'GP', 'M1', 'Re', 'Re(2)', ...
      'BLA', 'BLA(2)', 'S1BF(3)', 'CeM', 'RT', 'S1BF(4)', 'VPM', ...
      'CA3', 'CA3(2)', 'CA1', 'DG', 'Re(3)', 'PRh', ...
      'DLEnt', 'DIEnt', 'VIEnt', 'VIEnt(2)', 'DG(2)', 'Ment', ...
      'DG(3)', 'Post', 'RSD', 'DLEnt(2)', 'Ment(2)', 'TEA', ...
      'CEnt', 'CEnt(2)', 'V1', 'Prs', 'Post(2)'};
```

### Output Structure
```
data_path/Matt_files/
└── tc_artifact_corrected.mat    # Corrected traces (37×N matrix)
```

---

## Usage

### Demo Mode (Test Workflow)
```matlab
% Open Trace_QC_Pipeline.m
% Set DEMO_MODE = true
% Run script
Trace_QC_Pipeline
```

### Real Data Mode
```matlab
% Configure paths and mouse identifiers
DEMO_MODE = false;

paths = {
    'D:\Your\Data\Mouse1\Session1\TEST',
    'D:\Your\Data\Mouse1\Session2\TEST',
    ...
};

MICE = {'Mouse1_ID', 'Mouse2_ID', ...};

% Run pipeline
Trace_QC_Pipeline
```

**The pipeline will:**
1. Build mouse-specific statistics (automatic)
2. Process each session:
   - Verify channel orientation (interactive)
   - Select problematic traces (interactive)
   - Edit selected traces (interactive)
   - Review modifications (interactive)
3. Save corrected data to `tc_artifact_corrected.mat`

---

## Quality Control

**Console Output Metrics:**
```
═══════════════════════════════════════════════════
  PHASE 1: Building Mouse-Specific Statistics      
═══════════════════════════════════════════════════

→ Processing mouse: DEMO_MOUSE
  ✓ Collected 60000 total frames for DEMO_MOUSE

✓ MOUSE_DATA structure built successfully
  Ready for baseline statistics calculation

═══════════════════════════════════════════════════
  PHASE 2: Interactive Artifact Correction         
═══════════════════════════════════════════════════

→ Processing session: .../Session_01/Matt_files
  Starting interactive artifact correction (10 trials)
  ✓ Corrected data saved: tc_artifact_corrected.mat
```

**Modification Log Example:**
```
Selected area: BLA (ID: 8)
Set frames 1250-1280 to NaN for area BLA
Interpolated frames 3400-3450 for area BLA
Batch: Set frames 5000-5100 to NaN for all 37 areas
```

---

## Processing Parameters

**Signal Processing:**
```matlab
SMOOTHING_WINDOW = 5;      % Moving average window (frames)
BASELINE_OFFSET = 1;       % Baseline subtraction constant
```

**Artifact Detection:**
- Outlier threshold: ±3 standard deviations from mouse-specific median
- Channel flip detection: Visual inspection of first 600 frames
- Interpolation: Linear between nearest valid boundary points

**Display Settings:**
- Window size: 600 frames (~60 seconds at 10 Hz)
- Trace spacing: ΔF/F = 0.05 per region
- Sampling rate: 10 Hz (configurable)

---

## Requirements

**MATLAB Toolboxes:**
- Statistics and Machine Learning Toolbox

**Functions (in `functions/` subfolder):**
- `artifact_correction_system3.m` - Main interactive correction system
- `create_demo_data_structure.m` - Demo data generator (embedded)
- `generate_calcium_traces.m` - Synthetic trace generator (embedded)
- `generate_laser_signals.m` - Synthetic blue/purple generator (embedded)


---

## Troubleshooting

**Issue:** No sessions found for mouse
```
Solution: Verify mouse identifier appears in directory path
Example: For mouse '21_1L1R', path must contain '21_1L1R'
```

**Issue:** Missing .mat files
```
Solution: Ensure Matt_files folder contains:
  - tc_all_brain_areas_CORRECTED1.mat
  - trial#_BLUE.mat (all trials)
  - trial#_PURPLE.mat (all trials)
```

**Issue:** Channel flip not detected
```
Solution: Manually inspect first 600 frames
  - If all traces are inverted → Click "Traces Look Flipped"
  - Confirm flip → Click "Confirm Flip"
```

**Issue:** Cannot select trace
```
Solution: Click closer to trace line (within 0.05 ΔF/F)
  - Traces are vertically offset by 0.05 units
  - Aim for the center of the trace line
```

---

## Citation

```bibtex
@software{neuronal_qc_pipeline,
  author = {Zvi Kuhr},
  title = {Neuronal Trace Quality Control Pipeline for Fiber Photometry},
  year = {2025},
  url = {https://github.com/zvikuhr1-coder/neuronal-qc-pipeline}
}
```





## Contact

For questions or issues, please open an issue on GitHub or contact [your contact information].
