//
//  CameraTestView.swift
//  SLEAP iOS
//
//  Created by Suraj Laddagiri  on 9/24/26.
//

import SwiftUI
import UIKit

struct CameraTestView: View {
    private static let OriginalImage = UIImage(named: "reference.png")
    private static let OriginalRenderedImage = UIImage(named: "reference_overlay.png")
    @State private var ErrorMessage: String = "Unable to load image"
    @State private var DisplayedImage: UIImage? = CameraTestView.OriginalImage
    @State private var estimator: (any PoseEstimator)?
    @State private var isBusy = false
    @State private var modelStatus = "Model not loaded"
    @State private var modelLoaded = false
    @State private var skeleton: PoseSkeleton?
    
    
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
            
            HStack(spacing: 16) {
                Button("Predict"){
                    
                }
                .disabled(isBusy || !modelLoaded)
                
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

                Button("Reset") {
                    DisplayedImage = Self.OriginalImage
                    estimator = nil
                    skeleton = nil
                    modelLoaded = false
                    modelStatus = "Model not loaded"
                    ErrorMessage = "Unable to load image"
                }
                .disabled(isBusy)
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}

