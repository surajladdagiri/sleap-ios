# SLEAP iOS

**Animal pose estimation on iPhone and iPad, powered by SLEAP-trained models.**

A SwiftUI prototype that runs a trained fly pose model locally using ONNX Runtime with Core ML acceleration. It predicts body-part locations in images and video, draws skeleton overlays, and displays processing FPS.

## Demo

![Video inference demo](Demos/video.gif)

**[Try it on TestFlight (Link will work after Apple Approval)](https://testflight.apple.com/join/tQRBwW7R)**


## Training and model export

The Python notebook covers dataset preparation, training, evaluation,
ONNX export, and preparing the model and reference predictions for iOS.

- [View the notebook](python/training_demo_jupyter.ipynb)
- [Python setup and workflow](python/README.md)

Python is only needed to reproduce or modify the model workflow.
The iOS app includes the trained model and runs independently.

## What it does

- **Renderer Test:** Draw saved predictions over a reference image and compare with the Python reference overlay.
- **Prediction Test:** Run the model on the reference image and render the results.
- **Video Test:** Process the bundled video frame by frame, with overlays, processing FPS, and stop/reset controls.
- **On-device inference:** Use ONNX Runtime's Core ML execution provider without a server.



## Run it

Requires **Xcode 26** and **iOS/iPadOS 26.0**, matching the current project configuration.

1. Open `SLEAP iOS.xcodeproj`.
2. Let Swift Package Manager resolve the ONNX Runtime dependency.
3. Select your development team under **Signing & Capabilities**.
4. Choose a simulator or connected device, then build and run.

The trained model and sample media are included.

For video inference, open **Video Test**, select **Load Model**, then **Predict**.

## How it works

```text
Image or video frame
    → Grayscale preprocessing
    → ONNX inference with Core ML acceleration
    → Decode body-part coordinates
    → Draw skeleton overlay
    → Display in SwiftUI
```

The bundled SLEAP-NN model uses two stages: locate each fly, then predict its body parts from a crop. It accepts a **1024 × 1024 grayscale frame** and predicts **13 keypoints per fly**, with up to **two flies per frame**.

Preprocessing, inference, and rendering are separate components. An actor-based `PoseEstimator` protocol provides a common interface for potential future inference backends.

**Stack:** SwiftUI · AVFoundation · Core Graphics · ONNX Runtime 1.24.2 · Core ML

## Performance


| Device | iOS Version | Peak FPS |
| --- | --- | ---
| iPhone 15 Pro Max |27.0 | 17 |
| iPad Pro 11-inch, M1 | 27.0 | 14 |

The counter includes frame conversion, preprocessing, inference, decoding, and rendering. It measures processing throughput, not the video's source frame rate or screen refresh rate.

## Current scope

- Supports the bundled fly model and sample media.
- Predictions are independent across frames. **Persistent identity tracking is not implemented**, so animal colors can swap.
- Live camera inference, importing media, and exporting annotated videos are future work.
- Core ML acceleration is provided through ONNX Runtime; there is no standalone Core ML or custom Metal backend yet.


## Download an IPA

Unsigned IPA builds are available on the
[Releases page](https://github.com/surajladdagiri/sleap-ios/releases). These builds require signing before installation. For the simpler installation option, use the [TestFlight link](https://testflight.apple.com/join/tQRBwW7R).

### Sign and install with Sideloadly

You can sign and install the ipa it using
[Sideloadly](https://sideloadly.io/) on macOS or Windows with your own
Apple Account. A paid developer account is not required.

1. Download `SLEAP-iOS.ipa` from the Releases page.
2. Install Sideloadly from its official website.
3. If not already enabled, enable **Developer Mode** on your iPhone or iPad under **Settings → Privacy & Security** then restart and confirm when prompted.
4. Connect your device to your computer, unlock it, and accept
   the **Trust This Computer** prompt if shown.
5. Open Sideloadly, select your device, and drag the IPA into its window.
6. Enter your Apple Account and click **Start**. Complete any
   authentication prompts to sign and install the app.
7. If prompted on your device, trust your developer profile under
   **Settings → General → VPN & Device Management**.
8. Open **SLEAP iOS**.

With a free Apple Account, the signing expires after seven days.
Re-sign the app or configure Sideloadly's automatic refresh.

Your device must meet the build's minimum iOS/iPadOS requirement.
Signing does not make the app compatible with older OS versions.

For installation without handling signing yourself, use
[TestFlight](https://testflight.apple.com/join/tQRBwW7R).

## Credits

Built on the [SLEAP](https://github.com/talmolab/sleap) ecosystem from Talmo Lab: [SLEAP-NN](https://github.com/talmolab/sleap-nn) for training/export and [SLEAP-IO](https://github.com/talmolab/sleap-io) for Python reference visualization. Inference uses [ONNX Runtime](https://github.com/microsoft/onnxruntime).

## Check out my other work
[Portfolio](https://portfolio.sladdagiri.org)
