# Python workflow

Train, evaluate, and export the fly pose model used by [SLEAP iOS](../README.md).

The [Jupyter notebook](training_demo_jupyter.ipynb) adapts the [official SLEAP-NN training example](https://github.com/talmolab/sleap-nn/tree/main/example_notebooks) and adds ONNX testing, reference-image generation, and an output-type adaptation for the iOS runtime.

**Python is only needed to reproduce or modify this workflow. The iOS app runs independently using its bundled model.**

## Setup

Use Python **3.13** and [uv](https://docs.astral.sh/uv/). From the repository root:

```sh
cd python
uv sync --locked
uv run jupyter lab training_demo_jupyter.ipynb
```

`uv sync --locked` installs the environment recorded in `uv.lock`. The second command launches JupyterLab and opens the notebook. Run the notebook with this project's Python environment.

Keep the notebook's working directory set to this `python` folder: dataset, configuration, and output paths are relative to it.

The environment includes SLEAP-NN **0.3.3** with export dependencies, SLEAP-IO **0.9.2**, PyTorch **2.14.0**, JupyterLab, and Matplotlib. Keep `pyproject.toml`, `uv.lock`, `.python-version`, and `src/` together; the project uses a local Python package under `src/sleap_python`.

## Notebook workflow

Run cells in order for a complete training run.

| Stage | What it does |
| --- | --- |
| Setup | Import libraries and select CUDA, Apple MPS, or CPU for prediction |
| Dataset | Download and load train/validation/test labels and a sample video |
| Inspect | Display original frames alongside labeled skeletons |
| Configure | Write centroid and centered-instance training configurations |
| Train | Train both models, configured for up to 25 epochs each |
| Evaluate | Compare predictions with held-out test annotations |
| Video | Predict and track the first 300 frames, then render a video |
| Export | Export the combined model to ONNX and add skeleton connectivity |
| ONNX test | Inspect the exported interface and run tracked video inference |
| Reference assets | Save an input image, prediction JSON, and SLEAP-IO overlay |
| iOS adaptation | Save a separate model with an Int32 validity output |

Training is the longest step. A supported GPU is preferable; runtime depends on hardware. The prediction `device` variable and the trainer settings in the YAML configurations are separate, so inspect the training startup log to confirm its accelerator.

### Dataset and model

The notebook downloads **flies13** (`wt_gold.13pt/tracking_split2`) from the SLEAP dataset storage URLs included in its download cell. The packaged `.slp` files contain annotations and embedded images.

Frames are **1024 × 1024 grayscale**, with two flies and **13 body-part labels per fly**.

The top-down model has two stages:

1. **Centroid:** locate each fly using the thorax anchor; input scale 0.5.
2. **Centered instance:** predict the body parts within a 160 × 160 crop.

Training uses U-Net backbones, an initial learning rate of `1e-4`, and rotation augmentation from −180° to +180°. The saved YAML files contain the full settings.

### Existing training runs

The training cell raises `FileExistsError` if either model directory already exists. This prevents accidentally training over previous results.

To reuse completed checkpoints, skip the training calls and define:

```python
centroid_dir = "models/centroid"
centered_instance_dir = "models/centered_instance"
```

Run the earlier setup/data cells needed by later sections. Both trained model directories must already contain their checkpoints and configuration files; the app's ONNX model does not replace those training artifacts.

## Outputs

| Location | Contents |
| --- | --- |
| `configs/` | Training YAML files |
| `models/centroid/`, `models/centered_instance/` | Training outputs and checkpoints |
| `trained_models.zip` | Optional archive of the model directories |
| `test_metrics_summary.json` | Held-out evaluation summary |
| `test.predictions.slp` | Test predictions |
| `fly_clip.tracked.viz.mp4` | Python checkpoint inference with tracking |
| `fly_clip.onnx.tracked.viz.mp4` | Exported ONNX inference with Python tracking |
| `exports/flies_topdown/` | ONNX models, metadata, and exported configurations |
| `ios_reference/` | Reference PNG, prediction JSON, and overlay PNG |

Download cells skip files that already exist. Other cells can overwrite generated configurations, predictions, exports, and reference assets. Preserve any results you want to retain before rerunning those sections.

## Copying results into the iOS app

After completing the final export-adaptation cell, copy:

| Python output | Destination in the repository |
| --- | --- |
| `exports/flies_topdown/model_ios.onnx` | `Model/model.onnx` — rename when copying |
| `exports/flies_topdown/export_metadata.json` | `Model/export_metadata.json` |
| `ios_reference/reference.png` | `Reference/reference.png` |
| `ios_reference/reference.json` | `Reference/reference.json` |
| `ios_reference/reference_overlay.png` | `Reference/reference_overlay.png` |
| `fly_clip.mp4` | `Model/fly_clip.mp4` |

The original export remains `model.onnx` in the Python export folder. The notebook uses its Boolean `instance_valid` output for reference generation.

The final cell creates **`model_ios.onnx`**, replacing that public output with **`instance_valid_int32`** through an ONNX Cast. This addresses the Boolean tensor inspection limitation encountered in the Objective-C/Swift runtime bindings. It preserves the model weights and mask meaning.

Use the adapted file for the app. The notebook performs a graph check on this file; that check alone is not an end-to-end mobile accuracy test.

Skeleton connections are stored in metadata as `edge_inds`. Copy the matching metadata alongside the model so the app can draw lines between body parts.

**Python tracking is separate from the exported pose graph.** The notebook's local-queues tracker does not become part of the iOS model; the current app predicts each frame independently.

## Recorded test results

The saved Python evaluation summary reports:

| Metric | Value |
| --- | --- |
| OKS mAP | 0.3987 |
| mPCK | 0.6949 |
| Median keypoint distance | 2.5718 px |
| 90th-percentile keypoint distance | 6.8632 px |

These describe the Python test run, not an iOS/Core ML benchmark.

## Credits

Based on the [SLEAP-NN example notebooks](https://github.com/talmolab/sleap-nn/tree/main/example_notebooks). Training/export uses [SLEAP-NN](https://github.com/talmolab/sleap-nn), visualization uses [SLEAP-IO](https://github.com/talmolab/sleap-io), and exported inference uses [ONNX Runtime](https://github.com/microsoft/onnxruntime).

## Check out my other work

[Portfolio](https://portfolio.sladdagiri.org)
