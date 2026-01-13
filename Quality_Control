# Neuronal Trace Quality Control Pipeline

**Interactive quality control system for dual-wavelength fiber photometry data with artifact detection and correction**

---

## Overview

This pipeline provides comprehensive quality control for calcium imaging data recorded with dual-wavelength fiber photometry. The system features interactive artifact detection, multiple correction strategies, and session-wide operations to ensure high-quality neuronal activity traces.

### Key Features

- **Dual-wavelength processing**: Handles blue (calcium-sensitive) and purple (isosbestic/artifact) channels
- **Interactive artifact detection**: Visualize and manually review detected artifacts
- **Multiple correction options**: NaN removal, interpolation, blue-only mode, and channel swapping
- **Session-wide operations**: Apply corrections across all brain regions simultaneously
- **Mouse-specific statistics**: Calculate baseline characteristics across recording sessions
- **Demo mode**: Test the pipeline with synthetic data without requiring actual recordings

---

## Table of Contents

- [Installation](#installation)
- [Quick Start](#quick-start)
- [Pipeline Overview](#pipeline-overview)
- [Demo Mode](#demo-mode)
- [Processing Real Data](#processing-real-data)
- [Interactive Correction Options](#interactive-correction-options)
- [Data Structure](#data-structure)
- [Troubleshooting](#troubleshooting)
- [Citation](#citation)

---

## Installation

### Prerequisites

- MATLAB R2019b or later
- No additional toolboxes required

### Setup

1. Clone this repository:
```bash
git clone https://github.com/yourusername/neuronal-trace-qc.git
cd neuronal-trace-qc
```

2. Add the repository to your MATLAB path:
```matlab
addpath(genpath('path/to/neuronal-trace-qc'))
```

---

## Quick Start

### Running the Demo

The easiest way to test the pipeline is with the built-in demo mode:

```matlab
% Open Trace_QC_Pipeline.m
% Set DEMO_MODE = true (default)
% Run the script
Trace_QC_Pipeline
```

The demo will:
1. Generate synthetic calcium imaging data (1 mouse, 10 sessions, 37 brain regions)
2. Create realistic artifacts (spikes, channel swaps, motion artifacts)
3. Walk you through the interactive correction workflow

**No data files needed!**

### Processing Your Data

```matlab
% Open Trace_QC_Pipeline.m
% Set DEMO_MODE = false
% Configure your data paths
% Run the script
Trace_QC_Pipeline
```

---

## Pipeline Overview

The quality control pipeline operates in two phases:

### Phase 1: Build Mouse-Specific Baseline Statistics

**Purpose**: Aggregate data across all recording sessions for each mouse to establish baseline signal characteristics.

**Process**:
1. Scan all session directories for each mouse
2. Load neuronal traces (blue - purple subtracted signal)
3. Load raw blue and purple laser signals
4. Accumulate data across sessions
5. Calculate median and standard deviation for artifact detection

**Output**: `MOUSE_DATA` structure containing baseline statistics

---

### Phase 2: Interactive Artifact Correction

**Purpose**: Detect and correct artifacts in individual sessions with user guidance.

**Process**:

#### Step 1: Channel Flip Check
- Display first 600 frames of all brain regions
- User confirms correct channel configuration
- Option to flip channels if purple/blue were reversed

#### Step 2: Trace Selection
- Navigate through full session using scroll wheel
- Click on problematic traces to edit them
- Visual highlighting of all 37 brain regions

#### Step 3: Trace Editing
- Detailed view of selected brain region
- Compare corrected signal with raw blue/purple channels
- Apply corrections to specific frame ranges

#### Step 4: Review and Save
- Review all modifications
- Accept changes or return to editing
- Save corrected data automatically

---

## Demo Mode

### What the Demo Creates

The demo mode generates realistic synthetic data that mimics actual fiber photometry recordings:

**Synthetic Data Characteristics**:
- **1 mouse** with **10 recording sessions**
- **37 brain regions** per session
- **6000 frames per session** (10 trials × 600 frames)
- Calcium transients with realistic rise/decay kinetics
- Baseline drift simulating photobleaching
- Motion artifacts present in both channels
- Intentional artifacts for testing correction strategies

**Artifact Types Included**:
- Extreme spikes (>30 SD from baseline) - 20% of regions
- Channel swap artifacts - 10% of regions
- Purple > Blue inconsistencies - 10% of regions
- Gradual drift artifacts

### Demo Data Location

```
[TEMP_DIR]/neuronal_qc_demo/
└── DEMO_MOUSE/
    ├── Session_01/
    │   ├── Matt_files/
    │   │   ├── tc_all_brain_areas_CORRECTED1.mat
    │   │   ├── trial1_BLUE.mat
    │   │   ├── trial1_PURPLE.mat
    │   │   └── ... (trials 2-10)
    │   └── 20240101_trial1.dcimg (dummy file)
    ├── Session_02/
    └── ... (sessions 3-10)
```

---

## Processing Real Data

### Required Data Structure

Your data must follow this directory structure:

```
[EXPERIMENT_ROOT]/
└── [MOUSE_ID]/
    └── [SESSION_NAME]/
        ├── Matt_files/
        │   ├── tc_all_brain_areas_CORRECTED1.mat  % Neuronal traces (blue-purple)
        │   ├── trial1_BLUE.mat                     % Blue channel signal
        │   ├── trial1_PURPLE.mat                   % Purple channel signal
        │   ├── trial2_BLUE.mat
        │   ├── trial2_PURPLE.mat
        │   └── ...
        └── 202*.dcimg                              % Trial files for counting
```

### Configuration

Edit `Trace_QC_Pipeline.m`:

```matlab
% Set demo mode to false
DEMO_MODE = false;

% Configure your data paths
paths = {
    'D:\Experiment\Mouse1\Session1',...
    'D:\Experiment\Mouse1\Session2',...
    'D:\Experiment\Mouse2\Session1',...
};

% Define mouse identifiers (must match directory names)
MICE = {'Mouse1', 'Mouse2'};
```

### File Format Requirements

**Neuronal Traces** (`tc_all_brain_areas_CORRECTED1.mat`):
- Variable: `tc_all_brain_areas_CORRECTED`
- Dimensions: `[37 brain regions × N frames]`
- Values: Preprocessed ΔF/F₀ (blue - purple)

**Laser Signals** (`trial#_BLUE.mat`, `trial#_PURPLE.mat`):
- Variable name: `trial#_blue` or `trial#_purple` (dynamic)
- Dimensions: `[37 brain regions × frames per trial]`
- Values: Raw fluorescence intensity (baseline ~1.0)

---

## Interactive Correction Options

### Single-Area Corrections

Apply to the currently selected brain region:

| Option | Description | Best For |
|--------|-------------|----------|
| **Set Range to NaN** | Remove frames completely | Long artifacts (>20 frames) |
| **Use Blue for Range** | Replace with raw blue signal | Purple channel artifacts |
| **Interpolate Range** | Linear interpolation | Short artifacts (<20 frames) |
| **Set Entire to NaN** | Remove entire trace | Completely corrupted regions |
| **Use Blue Entire** | Replace entire trace with blue | Systematic purple issues |

### Batch Operations

Apply to **all 37 brain regions** simultaneously:

| Option | Description | Use Case |
|--------|-------------|----------|
| **Batch NaN Range** | Set frame range to NaN (all areas) | Global motion artifacts |
| **Batch Blue Range** | Use blue signal for range (all areas) | Systematic purple spikes |
| **Batch Interpolate** | Interpolate range (all areas) | Short global artifacts |

### Session-Wide Operations

| Option | Description | When to Use |
|--------|-------------|-------------|
| **Channel Swap** | Flip blue ↔ purple for entire session | Channels were recorded backwards |
| **Blue-Only Mode** | Use only blue signal (no subtraction) | Purple channel is unusable |

---

## Data Structure

### Brain Regions (37 Total)

The pipeline processes 37 brain regions arranged in the fiber array:

```
Row 1: S1BF, CPU, S1BF(2), GP, M1, Re, Re(2)
Row 2: BLA, BLA(2), S1BF(3), CeM, RT, S1BF(4), VPM, CA3, CA3(2), CA1, DG, Re(3)
Row 3: PRh, DLEnt, DIEnt, VIEnt, VIEnt(2), DG(2), Ment, DG(3), Post, RSD
Row 4: DLEnt(2), Ment(2), TEA, CEnt, CEnt(2), V1, Prs, Post(2)
```

**Abbreviations**:
- S1BF: Primary Somatosensory Cortex Barrel Field
- CPU: Caudate Putamen  
- GP: Globus Pallidus
- M1: Primary Motor Cortex
- Re: Nucleus Reuniens
- BLA: Basolateral Amygdala
- CeM: Central Medial Amygdala
- RT: Reticular Thalamic Nucleus
- VPM: Ventral Posteromedial Thalamic Nucleus
- CA1/CA3: Hippocampal regions
- DG: Dentate Gyrus
- PRh: Perirhinal Cortex
- DLEnt/DIEnt/VIEnt: Entorhinal cortex regions
- Ment: Medial Entorhinal Cortex
- Post: Postsubiculum
- RSD: Retrosplenial Dysgranular Cortex
- TEA: Temporal Association Area
- CEnt: Caudomedial Entorhinal Cortex
- V1: Primary Visual Cortex
- Prs: Presubiculum

### Output Files

**Per Session**:
```
[SESSION_DIR]/Matt_files/tc_artifact_corrected.mat
```
- Variable: `tc_artifact_corrected`
- Dimensions: `[37 regions × N frames]`
- Content: Quality-controlled neuronal traces

---

## Troubleshooting

### Common Issues

**Issue**: "Mouse X not found in MOUSE_DATA"
- **Cause**: Mouse identifier doesn't match directory structure
- **Solution**: Verify `MICE` cell array matches folder names exactly

**Issue**: "Insufficient data for artifact detection"
- **Cause**: Too few valid frames after preprocessing
- **Solution**: Check that trials loaded correctly, verify file format

**Issue**: No artifacts detected when they clearly exist
- **Cause**: Artifact detection thresholds too conservative
- **Solution**: Adjust `extreme_spike_threshold` in artifact detection function (default: 30 SD)

**Issue**: Too many false positive artifact detections
- **Cause**: High natural signal variability
- **Solution**: Increase detection thresholds or use blue-only mode

### Performance Tips

- **Memory**: Each session requires ~500 MB RAM for 6000 frames
- **Processing time**: ~1-2 minutes per session (excluding user interaction)
- **Display**: Use dual monitors for easier trace review

### Data Quality Checks

Before running the pipeline, verify:
- ✓ Blue and purple signals have similar noise levels
- ✓ Subtracted signal (blue-purple) shows calcium transients
- ✓ No systematic drift across trials
- ✓ ROIs are well-aligned with fiber positions

---

## Pipeline Parameters

### Adjustable Settings (in `Trace_QC_Pipeline.m`)

```matlab
SMOOTHING_WINDOW = 5;     % Moving average window (frames)
BASELINE_OFFSET = 1;      % Baseline correction offset
```

### Detection Thresholds (in `artifact_correction_system.m`)

```matlab
extreme_spike_threshold = 30;              % SD for spike detection
blue_purple_inconsistency_threshold = 6;   % SD for channel mismatch
min_artifact_gap = 5;                      % Frames to merge artifacts
```

---

## Example Workflow

```matlab
% 1. Start MATLAB and navigate to pipeline directory
cd('path/to/neuronal-trace-qc')

% 2. Run demo to familiarize yourself with the interface
Trace_QC_Pipeline  % with DEMO_MODE = true

% 3. Configure for your data
% Edit Trace_QC_Pipeline.m:
%   - Set DEMO_MODE = false
%   - Update paths and MICE arrays

% 4. Process your data
Trace_QC_Pipeline

% 5. Load corrected data for analysis
load('path/to/session/Matt_files/tc_artifact_corrected.mat')

% 6. Analyze traces
plot(tc_artifact_corrected(1,:))  % Plot first brain region
```

---

## Best Practices

### Before Processing
1. **Verify data integrity**: Check that all required files exist
2. **Review raw traces**: Look at uncorrected data to identify issues
3. **Test on one session**: Process a single session before batch processing

### During Processing
1. **Channel flip check**: Carefully verify first 600 frames look normal
2. **Systematic review**: Scroll through entire session before making corrections
3. **Conservative corrections**: When in doubt, use interpolation over NaN
4. **Document changes**: The pipeline logs all modifications

### After Processing
1. **Spot check**: Manually review several corrected traces
2. **Compare sessions**: Check for consistency across sessions
3. **Validate signal**: Verify calcium transients are preserved
4. **Backup original**: Keep uncorrected data for reference

---

## Citation

If you use this pipeline in your research, please cite:

```bibtex
@software{neuronal_trace_qc,
  author = {Your Name},
  title = {Neuronal Trace Quality Control Pipeline},
  year = {2024},
  url = {https://github.com/yourusername/neuronal-trace-qc}
}
```

---


---

**Last Updated**: January 2025
