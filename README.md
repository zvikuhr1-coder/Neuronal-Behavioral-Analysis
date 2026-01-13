# Neuronal-Behavioral-Analysis

A comprehensive MATLAB pipeline for integrating multi-region calcium imaging with behavioral tracking to decode neural representations of memory and decision-making in freely moving mice.

---

## Overview

This repository provides an end-to-end analysis framework for studying the neural basis of behavior through synchronized calcium imaging and pose tracking. The pipeline processes raw fiber photometry recordings from 48 simultaneous brain regions, aligns them with DeepLabCut behavioral tracking, performs quality control, and applies machine learning to decode behavioral states from distributed neural activity patterns.

**Key Capabilities:**
- **Large-scale neural recording**: Dual-wavelength fiber photometry from 37 brain regions with automated hemodynamic correction
- **Behavioral synchronization**: Frame-accurate alignment of 10Hz imaging with 20Hz video tracking
- **Quality assurance**: Interactive artifact detection and correction with mouse-specific statistical validation
- **Neural decoding**: Multi-algorithm classification to predict behavior from brain activity patterns
- **Comprehensive visualization**: Publication-ready figures with detailed feature importance analysis

---

## Repository Structure

```
Neuronal-Behavioral-Analysis/
│
├── 01_Neuronal_Preprocessing/          # Fiber photometry signal extraction
│   ├── Neuronal_Preprocessing_Pipeline.m
│   ├── functions/
│   └── README.md
│
├── 02_Behavioral_Synchronization/      # DeepLabCut tracking alignment
│   ├── Behavioral_Tracking_Pipeline.m
│   ├── functions/
│   └── README.md
│
├── 03_Quality_Control/                 # Interactive trace correction
│   ├── Trace_QC_Pipeline.m
│   ├── functions/
│   └── README.md
│
├── 04_Neural_Classification/           # Machine learning decoding
│   ├── Classification_Demo.m
│   ├── README.md
│   └── figures/
│
└── README.md                           # This file
```

---

## Pipeline Workflow

### Module 1: Neuronal Signal Preprocessing
Extracts calcium-dependent signals from raw dual-wavelength fiber photometry recordings across 37 brain regions arranged in a 4×12 fiber array.

**Input:** Raw `.dcimg` files from Hamamatsu cameras  
**Output:** ΔF/F₀ normalized signals with hemodynamic correction

**Key Features:**
- Semi-automated ROI placement with corner landmark interpolation
- Dual-wavelength correction (405nm isosbestic / 470nm GCaMP)
- Baseline normalization and temporal smoothing

**[Documentation →](01_Neuronal_Preprocessing/README.md)**

---

### Module 2: Behavioral Tracking Synchronization
Aligns DeepLabCut pose estimation with calcium imaging acquisition through FFmpeg-extracted timestamps and LED-based trial detection.

**Input:** Video files (`.avi`), DLC tracking CSV, imaging data  
**Output:** Frame-aligned neural activity and position coordinates

**Key Features:**
- Arena boundary filtering with polygon ROI
- Sub-20ms temporal alignment accuracy
- Outlier correction via moving window interpolation
- Multi-trial concatenation with consistent frame mapping

**[Documentation →](02_Behavioral_Synchronization/README.md)**

---

### Module 3: Trace Quality Control
Interactive correction of motion artifacts, photobleaching, and channel inconsistencies using mouse-specific statistical baselines.

**Input:** Dual-wavelength traces from multiple sessions  
**Output:** Artifact-corrected neuronal activity

**Key Features:**
- Mouse-specific ±3σ outlier visualization
- Channel flip correction
- Flexible editing: NaN replacement, interpolation, or single-channel substitution
- Batch operations across all 37 brain regions
- Demo mode with synthetic data generation

**[Documentation →](03_Quality_Control/README.md)**

---

### Module 4: Neural Classification
Multi-algorithm machine learning pipeline to decode behavioral states (novel vs. familiar object investigation) from distributed neural activity patterns.

**Input:** Neural activity during object contacts  
**Output:** Classification models, accuracy metrics, feature importance

**Key Features:**
- Four complementary algorithms: LDA, Random Forest, KNN, Linear SVM
- Temporal train/test split with safety gap (prevents data leakage)
- Individual mouse and population-level models
- Comprehensive visualization with feature importance analysis
- Demo mode: synthetic data generator for testing workflow

**[Documentation →](04_Neural_Classification/README.md)**

---

## Technical Highlights

### Data Scale
- **Spatial**: 48 simultaneous recording sites across cortical and subcortical regions
- **Temporal**: 10Hz imaging synchronized with 20Hz behavioral tracking
- **Sessions**: Multi-session concatenation with mouse-specific normalization
- **Analysis**: 37 brain regions × 100+ behavioral events per mouse

### Analytical Rigor
- **Temporal validation**: Chronological train/test splits prevent overfitting
- **Statistical controls**: Mouse-specific baselines and ±3σ thresholds
- **Multi-algorithm consensus**: Robust findings across 4 classification methods
- **Artifact mitigation**: Interactive QC with visual inspection and batch correction

### Software Engineering
- **Modular design**: Independent modules with clear input/output contracts
- **Error handling**: Try-catch blocks with informative console output
- **Reproducibility**: Fixed random seeds, saved parameters, demo modes
- **Documentation**: Detailed README files with usage examples and troubleshooting
- **Visualization**: Publication-ready figures with consistent styling

---

## Requirements

**MATLAB:** R2018b or later

**Toolboxes:**
- Statistics and Machine Learning Toolbox
- Image Processing Toolbox

**External Software:**
- [FFmpeg](https://ffmpeg.org/download.html) - Video timestamp extraction
- [DeepLabCut](https://deeplabcut.github.io/) - Pose estimation (run externally, CSV imported)

**Hardware:**
- Hamamatsu C13440/C11440 cameras for fiber photometry acquisition

---

## Quick Start

### 1. Clone Repository
```bash
git clone https://github.com/yourusername/Neuronal-Behavioral-Analysis.git
cd Neuronal-Behavioral-Analysis
```

### 2. Run Demo (No Data Required)
```matlab
% Test neural classification pipeline with synthetic data
cd 04_Neural_Classification
Classification_Demo
```

### 3. Process Real Data
```matlab
% Set your data path
data_path = 'C:\Path\To\Your\Experiment';

% Module 1: Extract neural signals
cd 01_Neuronal_Preprocessing
Neuronal_Preprocessing_Pipeline

% Module 2: Synchronize behavior
cd ../02_Behavioral_Synchronization
Behavioral_Tracking_Pipeline

% Module 3: Quality control
cd ../03_Quality_Control
Trace_QC_Pipeline

% Module 4: Classification analysis
cd ../04_Neural_Classification
% [Load your processed data and run classification]
```

---


## Key Publications & Methods

**Fiber Photometry:**
- Dual-wavelength correction: Lerner et al., 2015 (*Cell*)
- ΔF/F₀ normalization: Gunaydin et al., 2014 (*Nat Neurosci*)

**Behavioral Tracking:**
- DeepLabCut: Mathis et al., 2018 (*Nat Neurosci*)

**Machine Learning:**
- Temporal train/test splits: Varoquaux et al., 2017 (*NeuroImage*)
- Feature importance: Breiman, 2001 (*Mach Learn*)

---

## Performance Metrics

**Preprocessing:**
- ROI placement: <2 minutes per experiment (semi-automated)
- Signal extraction: ~5 minutes per trial (batch processing)

**Synchronization:**
- Temporal alignment: <20ms accuracy
- Arena filtering: Automatic polygon exclusion

**Classification:**
- Training time: <10 seconds per mouse (LDA/SVM)
- Accuracy: 70-85% (real data), ~50% (random labels, as expected)

---

## Future Enhancements

- [ ] GPU acceleration for Random Forest training
- [ ] Deep learning models (LSTM, Transformer) for temporal dynamics
- [ ] Cross-validated hyperparameter tuning
- [ ] Dimensionality reduction (PCA, t-SNE) visualization
- [ ] Multi-class classification (>2 behavioral states)
- [ ] Region-specific analysis (hippocampus-only, cortex-only models)

---

## Citation

If you use this pipeline in your research, please cite:

```bibtex
@software{neuronal_behavioral_analysis_2025,
  author = {[Zvi Kuhr]},
  title = {Neuronal-Behavioral-Analysis: Integrated Pipeline for Neural Decoding},
  year = {2025},
  url = {https://github.com/yourusername/Neuronal-Behavioral-Analysis}
}
```



## Contact

**Author:** Zvi Kuhr
**Email:** zvikuhr1@gmail.com
**GitHub:** [@zvikuhr1-coder](https://github.com/zvikuhr1-coder)  
**LinkedIn:** [www.linkedin.com/in/zvi-kuhr]

For questions, bug reports, or collaboration opportunities, please [open an issue](https://github.com/yourusername/Neuronal-Behavioral-Analysis/issues).

---

## Acknowledgments

This pipeline was developed for neuroscience research investigating the neural basis of memory and decision-making. Special thanks to the open-source communities behind DeepLabCut, FFmpeg, and MATLAB File Exchange contributors whose tools enabled this work.
