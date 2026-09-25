//
//  VideoTestView.swift
//  SLEAP iOS
//
//  Created by Suraj Laddagiri  on 9/24/26.
//



import SwiftUI
import UIKit

struct VideoTestView: View {
    private enum VideoProcessingError: LocalizedError {
        case preprocessingFailed
        case renderingFailed

        var errorDescription: String? {
            switch self {
            case .preprocessingFailed:
                return "Could not preprocess a video frame."
            case .renderingFailed:
                return "Could not render a prediction."
            }
        }
    }
    
    
    private static let OriginalImage = UIImage(named: "reference.png")
    private static let OriginalRenderedImage = UIImage(named: "reference_overlay.png")
    @State private var ErrorMessage: String = "Unable to load image"
    @State private var DisplayedImage: UIImage? = VideoTestView.OriginalImage
    @State private var estimator: (any PoseEstimator)?
    @State private var isBusy = false
    @State private var modelStatus = "Model not loaded"
    @State private var modelLoaded = false
    @State private var skeleton: PoseSkeleton?
    @State private var processedFrames = 0
    @State private var processingFPS = 0.0
    @State private var processingTask: Task<Void, Never>?
    @State private var videoStatus = "Ready to process video"
    
    
    var body: some View {
        VStack(spacing: 20) {
            
            if let DisplayedImage{
                Image(uiImage: DisplayedImage)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(Color.green, lineWidth: 4)
                    )
            }else {
                Text(ErrorMessage)
            }
            
            Text(modelStatus)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(videoStatus)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(
                "\(processingFPS, specifier: "%.1f") processing FPS · \(processedFrames) frames"
            )
            .font(.caption.monospacedDigit())
            
            
            HStack(spacing: 16) {
                Button("Predict") {
                    guard let activeEstimator = estimator,
                          let activeSkeleton = skeleton else {
                        videoStatus = "Load the model first."
                        return
                    }

                    guard let videoURL = Bundle.main.url(
                        forResource: "fly_clip",
                        withExtension: "mp4"
                    ) else {
                        videoStatus = "fly_clip.mp4 was not found."
                        return
                    }

                    isBusy = true
                    processedFrames = 0
                    processingFPS = 0
                    videoStatus = "Opening video..."

                    processingTask = Task { @MainActor in
                        defer {
                            isBusy = false
                            processingTask = nil
                        }

                        do {
                            let frameReader = try await VideoFrameReader(url: videoURL)

                            defer {
                                frameReader.cancel()
                            }

                            let preprocessor = Preprocessor()
                            let renderer = PoseRenderer()

                            var intervalStart = ProcessInfo.processInfo.systemUptime
                            var intervalFrames = 0

                            videoStatus = "Processing video..."

                            while let frame = try await frameReader.nextFrame() {
                                try Task.checkCancellation()

                                // Prepare this frame for the model.
                                guard let input = preprocessor.prepare(
                                    image: frame.image
                                ) else {
                                    throw VideoProcessingError.preprocessingFailed
                                }

                                // Wait for this prediction before reading another frame.
                                let prediction = try await activeEstimator.predict(
                                    input: input,
                                    skeleton: activeSkeleton
                                )

                                try Task.checkCancellation()

                                // Draw predictions onto the same source frame.
                                guard let renderedImage = renderer.render(
                                    image: frame.image,
                                    prediction: prediction
                                ) else {
                                    throw VideoProcessingError.renderingFailed
                                }

                                DisplayedImage = renderedImage
                                processedFrames += 1
                                intervalFrames += 1

                                // Update throughput approximately once per second.
                                let now = ProcessInfo.processInfo.systemUptime
                                let elapsed = now - intervalStart

                                if elapsed >= 1.0 {
                                    processingFPS = Double(intervalFrames) / elapsed
                                    intervalFrames = 0
                                    intervalStart = now
                                }

                                // Give other tasks an opportunity to run.
                                await Task.yield()
                            }

                            // Update FPS for the final partial interval.
                            let remainingTime =
                                ProcessInfo.processInfo.systemUptime - intervalStart

                            if intervalFrames > 0, remainingTime > 0 {
                                processingFPS = Double(intervalFrames) / remainingTime
                            }

                            videoStatus = "Finished: \(processedFrames) frames."

                        } catch is CancellationError {
                            videoStatus = "Stopped after \(processedFrames) frames."
                        } catch {
                            videoStatus = "Video failed: \(error.localizedDescription)"
                            print("Video processing error:", error)
                        }
                    }
                }
                .disabled(isBusy || !modelLoaded)
                
                Button("Stop") {
                    processingTask?.cancel()
                }
                .disabled(processingTask == nil)
                
                Button("Load Model") {
                    guard let modelURL = Bundle.main.url(
                        forResource: "model", withExtension: "onnx"
                    ) else {
                        modelStatus = "model.onnx was not found"
                        return
                    }
                    isBusy = true
                    modelStatus = "Loading model..."
                    
                    Task { @MainActor in
                        defer {
                            isBusy = false
                        }
                        do {
                            // Create a new instance of the model
                            let activeEstimator: any PoseEstimator
                            if let existingEstimator = estimator {
                                activeEstimator = existingEstimator
                            } else {
                                activeEstimator = ONNXPoseEstimator(modelURL: modelURL)
                            }
                            _ = try await activeEstimator.modelInterface()
                            estimator = activeEstimator
                            
                            
                            // Save the skeleton
                            guard let metadataURL = Bundle.main.url(
                                forResource: "export_metadata",
                                withExtension: "json"
                            ) else {
                                modelStatus = "export_metadata.json was not found."
                                return
                            }
                            let metadataData = try Data(contentsOf: metadataURL)
                            let sk = try JSONDecoder().decode(
                                PoseSkeleton.self,
                                from: metadataData
                            )
                            skeleton = sk
                            
                            
                            modelLoaded = true
                            modelStatus = "Model Loaded"
                            
                            
                        } catch {
                            modelStatus = "Model failed: \(error.localizedDescription)"
                        }
                    
                    }
                }
                .disabled(isBusy || modelLoaded)
                
                Button("Reference"){
                    DisplayedImage = Self.OriginalRenderedImage
                }
                .disabled(isBusy)

                Button("Reset") {
                    DisplayedImage = Self.OriginalImage
                    estimator = nil
                    skeleton = nil
                    modelLoaded = false
                    modelStatus = "Model not loaded"
                    ErrorMessage = "Unable to load image"
                    videoStatus = "Ready to process video"
                    processedFrames = 0
                    processingFPS = 0.0
                }
                .disabled(isBusy)
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .onDisappear {
            processingTask?.cancel()
        }
    }
}

