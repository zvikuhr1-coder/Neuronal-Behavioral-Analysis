# Module 01: Neuronal Signal Processing

## Overview
This module handles the ingestion and processing of raw fiber photometry data. It transforms high-speed video recordings (raw `.dcimg` or `.avi`) into normalized $\Delta F/F$ traces suitable for analysis.

## Key Features
* [cite_start]**Automated ROI Grid:** Programmatically generates a 48-fiber ROI grid to match experimental cannula geometry[cite: 1, 2, 3].
* [cite_start]**Signal De-interleaving:** Separates interleaved 405nm (Control) and 470nm (Signal) channels[cite: 107, 108].
* [cite_start]**Chamber Masking:** Automatically masks background noise using intensity thresholds or manual selection[cite: 107, 122].
* [cite_start]**dF/F Normalization:** Calculates normalized fluorescence changes using a median baseline correction to remove photobleaching trends[cite: 107, 153].

## Demo Mode
The script `Neuronal_Preprocessing_Pipeline.m` includes a **Demo Mode**. If no raw data is found in the directory, it generates a synthetic dataset (48 ROIs x 6000 frames) with simulated calcium events and noise, allowing users to verify the pipeline's logic without heavy data files.
