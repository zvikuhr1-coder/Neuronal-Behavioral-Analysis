# Mouse Neural Activity Classification Pipeline

## Overview

This pipeline demonstrates a machine learning approach to decode object recognition behavior from neural activity patterns across multiple brain regions. The goal is to predict whether a mouse is investigating a **novel** or **familiar** object based solely on the neural activity recorded from 37 different brain regions during the investigation.

## Scientific Context

### The Research Question
Can we predict what type of object (novel vs. familiar) a mouse is investigating by analyzing the pattern of neural activity across its brain?

This is a fundamental question in systems neuroscience:
- **Novel object recognition (NOR)** is a widely used behavioral paradigm to study learning and memory
- Different brain regions show distinct activity patterns during novel vs. familiar object investigation
- Machine learning can reveal which brain regions contain the most predictive information
- Classification accuracy indicates how well neural patterns encode behavioral states

### Why This Matters
1. **Understanding memory encoding**: Identifying which brain regions differentiate novel from familiar objects reveals the neural basis of recognition memory
2. **Neural decoding**: Demonstrates that behavioral states can be "read out" from distributed brain activity
3. **Biomarker discovery**: High-performing models could identify neural signatures of memory dysfunction in disease models
4. **Systems-level insights**: Feature importance analysis reveals which brain regions work together during recognition memory

---

## Demo Version vs. Real Analysis

### What the Demo Does
This demonstration uses **randomly generated synthetic data** to showcase the pipeline structure and visualization capabilities. The synthetic data:
- Simulates neural activity from 37 brain regions
- Creates 6 "mice" with 100 object investigation contacts each
- Labels are assigned randomly (not based on actual neural patterns)
- **Expected accuracy: ~50% (chance level)** because there's no real signal

### Purpose of the Demo
The demo allows you to:
1. **Understand the pipeline logic** without needing access to the actual neural recordings
2. **See the visualization outputs** that would be generated from real data
3. **Examine the code structure** for adaptation to your own datasets
4. **Verify the analysis runs correctly** on your system

### Real Data Analysis
With actual neural recordings, this pipeline would:
- Load calcium imaging or electrophysiology data from behaving mice
- Extract neural activity during object investigation contacts
- Use verified behavioral labels (novel/familiar based on experimental design)
- **Achieve 60-90% accuracy** depending on brain regions recorded and data quality
- Reveal which brain regions carry the most information about object novelty

---

## Pipeline Architecture

### Step 1: Data Organization
```
For each mouse:
  ├── Novel object contacts (50 contacts)
  └── Familiar object contacts (50 contacts)
       └── Each contact: [37 brain regions × 1 activity value]
```

**Key decisions:**
- **Temporal splitting**: Training and test sets are split chronologically (not randomly) to avoid data leakage from temporal correlations
- **Safety gap**: A 5-contact buffer between training and test sets prevents adjacent timepoints from appearing in both sets
- **Standardization**: Z-score normalization ensures all brain regions contribute equally despite different baseline activity levels

### Step 2: Individual Mouse Models
Each mouse gets its own training/test split (75%/25%), enabling:
- **Within-subject analysis**: Controls for individual differences in brain anatomy and baseline activity
- **Subject-specific performance**: Some mice may have better signal-to-noise ratios
- **Generalization testing**: Can the model predict held-out data from the same animal?

### Step 3: Combined Multi-Mouse Dataset
All mice are pooled into one large dataset:
- **Increased statistical power**: More training examples improve model robustness
- **Cross-subject generalization**: Tests whether neural patterns are consistent across individuals
- **Population-level insights**: Reveals universal vs. mouse-specific coding strategies

### Step 4: Multi-Model Comparison
Four complementary algorithms are trained:

1. **Linear Discriminant Analysis (LDA)**
   - Fast, interpretable, assumes linear separability
   - Best for: Understanding which regions contribute most to classification
   
2. **Random Forest (RF)**
   - Non-linear, handles feature interactions, resistant to overfitting
   - Best for: Complex patterns and feature importance ranking
   
3. **K-Nearest Neighbors (KNN)**
   - Non-parametric, assumes similar activity patterns = similar behavior
   - Best for: Capturing local structure in neural state space
   
4. **Linear Support Vector Machine (SVM)**
   - Finds optimal separating hyperplane, maximizes margin
   - Best for: High-dimensional data with clear boundaries

**Why multiple models?**
- Different algorithms make different assumptions about data structure
- Consistent performance across models = robust, generalizable signal
- Divergent performance = specific model assumptions matter

### Step 5: Comprehensive Visualization

---

## Figure Descriptions

### Individual Mouse Analysis (6 figures, one per mouse)

Each figure contains 6 subplots:

#### Subplot 1: Model Accuracy Comparison
**Purpose**: Compare all four algorithms on the same test set

**What to look for:**
- Accuracy > 60% suggests real neural signal
- Similar performance across models = consistent, robust encoding
- One model >> others = data structure matches that model's assumptions

**Interpretation:**
- 50% = chance (no better than guessing)
- 60-70% = weak but detectable signal
- 70-85% = moderate signal, usable for decoding
- 85%+ = strong signal, neural activity highly predictive

---

#### Subplot 2: LDA Feature Importance (Top 15 Brain Regions)
**Purpose**: Which regions have the strongest linear relationship with behavior?

**What to look for:**
- High coefficients = regions whose activity strongly predicts object type
- Consistent top regions across mice = universal coding strategy
- Mouse-specific patterns = individual variation in neural coding

**Common findings:**
- **Hippocampus (CA1, CA3, DG)**: Often top predictors in memory tasks
- **Perirhinal cortex (PRh)**: Known for object recognition processing
- **Prefrontal regions (M1, Re)**: Executive control and attention
- **Sensory cortex (S1BF, V1)**: May reflect differential exploration

---

#### Subplot 3: Random Forest Feature Importance (Top 15 Brain Regions)
**Purpose**: Which regions provide the most information when considering non-linear patterns?

**What to look for:**
- OOB Error Increase = how much accuracy drops when that feature is shuffled
- Higher values = more critical for classification
- Compare to LDA: Different top regions? → Non-linear coding

**Advantage over LDA:**
- Captures feature interactions (e.g., CA1 × PRh activity patterns)
- Doesn't assume linear separability
- Often reveals regions missed by linear models

---

#### Subplot 4: Linear SVM Feature Importance (Top 15 Brain Regions)
**Purpose**: Which regions define the optimal decision boundary?

**What to look for:**
- Weight magnitude = importance for separating novel/familiar
- Should correlate with LDA if data is approximately linear
- Divergence suggests margin structure matters

**When SVM excels:**
- Clear separation exists but with narrow margin
- Some outliers need to be excluded from decision boundary
- Feature scaling matters (hence standardization)

---

#### Subplot 5: Confusion Matrix (Best Model)
**Purpose**: Detailed breakdown of prediction errors

**Matrix structure:**
```
                Predicted
              Novel  Familiar
Actual Novel    TP      FN
      Familiar  FP      TN
```

**What to look for:**
- **Balanced accuracy**: Both novel and familiar well-predicted
- **Systematic bias**: Model predicts one class more often
- **Symmetric errors**: FP ≈ FN suggests unbiased mistakes
- **Asymmetric errors**: FP >> FN means bias toward familiar (or vice versa)

**Real-world interpretation:**
- High TP, low FN = reliable novel object detection
- High TN, low FP = reliable familiar object detection
- Many FN = missing novel signals (false negatives)
- Many FP = false alarms (classifying familiar as novel)

---

#### Subplot 6: Data Distribution
**Purpose**: Verify balanced training and appropriate test set size

**What to look for:**
- Balanced classes = equal novel/familiar examples (prevents class imbalance bias)
- Sufficient test size = at least 20-30 examples for reliable accuracy estimates
- Proportional train/test = both classes split similarly

---

### Cross-Mouse Summary Figure

**Subplot 1: Model Performance Across All Mice**
- Grouped bar chart showing all 4 models × 6 mice
- Reveals consistency: Do all mice show similar patterns?
- Identifies outliers: Which mice have best/worst signal?

**Subplot 2: Average Model Performance**
- Overall comparison of algorithms
- Best model = highest average accuracy
- Most robust model = smallest variance across mice

**Key insights:**
- Consistent performance across mice = generalizable findings
- High variance = individual differences matter
- All models similar = signal is robust to algorithm choice

---

## The Power of This Analysis

### 1. Neural Decoding Demonstration
**Principle**: If we can predict behavior from neural activity, those brain regions encode that information.

**Impact**: 
- Validates brain regions as functionally relevant (not just correlates)
- Quantifies information content (accuracy = encoding strength)
- Enables real-time decoding applications (brain-machine interfaces)

### 2. Feature Importance = Functional Mapping
**Principle**: Regions with high feature importance are mechanistically involved in the computation.

**Impact**:
- Hypothesis generation: Which regions should we manipulate (optogenetics, lesions)?
- Circuit tracing: Feature importance suggests functional connectivity
- Comparative analysis: How do memory circuits differ across species/diseases?

### 3. Multi-Algorithm Consensus
**Principle**: Consistent findings across different algorithms indicate robust, generalizable signals.

**Impact**:
- Increases confidence in results (not algorithm-specific artifacts)
- Reveals data structure (linear vs. non-linear coding)
- Guides future experiments (what analysis approach is most appropriate?)

### 4. Individual vs. Population Analysis
**Principle**: Comparing within-subject and across-subject models reveals universality.

**Impact**:
- Universal patterns → conserved brain mechanisms
- Individual patterns → personalized medicine opportunities
- Hybrid approaches → population priors + individual calibration

### 5. Quantitative Benchmarking
**Principle**: Classification accuracy provides an objective, comparable metric.

**Impact**:
- Compare experimental manipulations (drug effects, genetic mutations)
- Track disease progression (accuracy degradation over time)
- Validate recording quality (low accuracy → technical problems?)

---

## Interpreting Results

### Demo Data (Random Labels)
✅ **Expected**: ~50% accuracy across all models and mice
✅ **Confirms**: Pipeline works correctly, no artificial inflation of accuracy
✅ **Baseline**: Real data should substantially exceed this performance

### Real Data (Actual Neural Recordings)
🎯 **Weak Signal (55-65% accuracy)**
- Subtle neural differences exist
- Large sample size needed for reliable decoding
- Consider focusing on specific brain regions

🎯 **Moderate Signal (65-80% accuracy)**
- Clear neural differentiation between conditions
- Publishable findings with proper validation
- Feature importance analysis is reliable

🎯 **Strong Signal (80-95% accuracy)**
- Robust encoding across multiple regions
- High information content in neural activity
- Suggests critical role in behavior

⚠️ **Suspiciously High (>95% accuracy)**
- Check for data leakage (temporal autocorrelation?)
- Verify train/test split is truly independent
- Consider if task is too easy (obvious perceptual differences?)

---

## Extending the Pipeline

### Potential Additions

1. **Cross-Validation**
   - K-fold CV for more robust accuracy estimates
   - Leave-one-session-out for temporal generalization

2. **Dimensionality Reduction**
   - PCA/t-SNE visualization of neural state space
   - Identify low-dimensional manifolds

3. **Time-Resolved Decoding**
   - Sliding window analysis during investigation
   - Reveal when novel/familiar signals emerge

4. **Region Subsets**
   - Train on specific circuits (e.g., hippocampus only)
   - Quantify information in different systems

5. **Multi-Class Classification**
   - More than 2 object types
   - Hierarchical classification (novel → subcategories)

6. **Regression Approaches**
   - Predict continuous exploration time
   - Decode object preference strength


---

## Citation

```bibtex
@software{behavioral_pipeline,
  author = {[Zvi Kuhr]},
  title = {Behavioral Tracking and Synchronization Pipeline},
  year = {2025},
  url = {https://github.com/zvikuhr1-coder/behavioral-pipeline}
}
```
