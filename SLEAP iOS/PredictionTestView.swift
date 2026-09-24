//
//  PredictionTestView.swift
//  SLEAP iOS
//
//  Created by Suraj Laddagiri  on 9/24/26.
//

import SwiftUI
import UIKit

struct PredictionTestView: View {
    private static let OriginalImage = UIImage(named: "reference.png")
    private static let OriginalRenderedImage = UIImage(named: "reference_overlay.png")
    @State private var ErrorMessage: String = "Unable to load image"
    @State private var DisplayedImage: UIImage? = PredictionTestView.OriginalImage
    @State private var estimator: (any PoseEstimator)?
    @State private var isBusy = false
    @State private var modelStatus = "Model not loaded"
    
    
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
                Button("Predict") {
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
                            let activeEstimator: any PoseEstimator
                            if let existingEstimator = estimator {
                                activeEstimator = existingEstimator
                            } else {
                                activeEstimator = ONNXPoseEstimator(modelURL: modelURL)
                            }
                            let info = try await activeEstimator.modelInterface()
                            
                            estimator = activeEstimator
                            modelStatus = "Model Loaded"
                            print("Inputs:", info.inputNames)
                            print("Outputs:", info.outputNames)
                            
                            
                        } catch {
                            modelStatus = "Model loading failed: \(error.localizedDescription)"
                        }
                    
                    }
                }
                .disabled(isBusy)
                
                Button("Reference"){
                    DisplayedImage = Self.OriginalRenderedImage
                }

                Button("Reset") {
                    DisplayedImage = Self.OriginalImage
                    estimator = nil
                    modelStatus = "Model not loaded"
                    ErrorMessage = "Unable to load image"
                }
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}

#Preview {
    PredictionTestView()
}
