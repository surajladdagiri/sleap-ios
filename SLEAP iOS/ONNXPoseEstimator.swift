//
//  ONNXPoseEstimator.swift
//  SLEAP iOS
//
//  Created by Suraj Laddagiri  on 9/24/26.
//

import Foundation
import OnnxRuntimeBindings

actor ONNXPoseEstimator: PoseEstimator {
    private enum DecodeError: Error {
        case missingOutput
        case invalidTensor
        case unexpectedShape
    }
    
    private let modelURL: URL
    private var environment: ORTEnv?
    private var session: ORTSession?
    
    init(modelURL: URL) {
        self.modelURL = modelURL
    }
    
    
    private func loadSession(force: Bool = false) throws -> ORTSession {
        
        // Check if a session is already established
        if let session, !force {
            return session
        }
        
        let environment = try ORTEnv(loggingLevel: .warning)
        
        let options = try ORTSessionOptions()

        try options.appendCoreMLExecutionProvider(
            withOptionsV2: [
                "ModelFormat": "MLProgram",
                "MLComputeUnits": "ALL"
            ]
        )
        
        let session = try ORTSession(env: environment, modelPath: modelURL.path, sessionOptions: options)
        
        self.environment = environment
        self.session = session
        
        return session
        
    }
    
    
    func modelInterface() async throws -> PoseModelInterface {
        let session = try loadSession()
        return PoseModelInterface(
            inputNames: try session.inputNames(),
            outputNames: try session.outputNames()
        )
    }
    
    
    
    
    private func readFloats(_ tensor: ORTValue) throws -> [Float] {
        let info = try tensor.tensorTypeAndShapeInfo()
        let data = try tensor.tensorData()
        let stride = MemoryLayout<Float>.stride
        
        guard info.elementType == .float,
              data.length % stride == 0 else {
            throw DecodeError.invalidTensor
        }
        
        var values = [Float](repeating: 0, count: data.length / stride)
        
        if !values.isEmpty {
            values.withUnsafeMutableBytes{ buffer in
                data.getBytes(buffer.baseAddress!, length: data.length)
            }
        }
        return values
    }
    
    private func readInt32s(_ tensor: ORTValue) throws -> [Int32] {
        let info = try tensor.tensorTypeAndShapeInfo()
        let data = try tensor.tensorData()
        let stride = MemoryLayout<Int32>.stride

        guard info.elementType == .int32,
              data.length % stride == 0 else {
            throw DecodeError.invalidTensor
        }

        var values = [Int32](repeating: 0, count: data.length / stride)

        if !values.isEmpty {
            values.withUnsafeMutableBytes { buffer in
                data.getBytes(buffer.baseAddress!, length: data.length)
            }
        }

        return values
    }
    
    
    
    
    func predict(input: PoseInput, skeleton: PoseSkeleton) async throws -> PosePrediction {
        let session = try loadSession()
        let inputData = NSMutableData(data: Data(input.pixels))

        let inputTensor = try ORTValue(
            tensorData: inputData,
            elementType: .uInt8,
            shape: [
                NSNumber(value: 1), // 1 image
                NSNumber(value: 1), // 1 channel
                NSNumber(value: input.height),
                NSNumber(value: input.width)
            ]
        )


        let outputNames = Set(try session.outputNames())

        // Run inference while keeping the input storage alive
        let outputs = try withExtendedLifetime(inputData) {
            try session.run(
                withInputs: ["image": inputTensor],
                outputNames: outputNames,
                runOptions: nil
            )
        }

        // Convert output dimensions into ordinary Swift values
        var shapes: [String: [Int]] = [:]

        for (name, tensor) in outputs {
            let info = try tensor.tensorTypeAndShapeInfo()
            shapes[name] = info.shape.map { $0.intValue }
        }
        
        
        // Retrieve the output tensors
        guard let peaksTensor = outputs["peaks"],
              let scoresTensor = outputs["peak_vals"],
              let validTensor = outputs["instance_valid_int32"] else {
            throw DecodeError.missingOutput
        }
        
        
        // Read their values
        let coordinates = try readFloats(peaksTensor)
        let scores = try readFloats(scoresTensor)
        let validity = try readInt32s(validTensor)
        
        
        //Ensure correct number/shape of predictions
        guard let peakShape = shapes["peaks"],
              peakShape.count == 4, //image number, animals, nodes, coordinates
              peakShape[0] == 1, //check that there is only 1 image
              peakShape[3] == 2 else { //check that there are 2 coordinates for each point
            throw DecodeError.unexpectedShape
        }

        let animalCount = peakShape[1]
        let nodeCount = peakShape[2]


        guard coordinates.count == animalCount * nodeCount * 2,
              scores.count == animalCount * nodeCount,
              validity.count == animalCount else {
            throw DecodeError.unexpectedShape
        }
        
        
        
        
        
        var instances: [PoseInstance] = []

        for animalIndex in 0..<animalCount {
            // Ignore empty animal slots.
            guard validity[animalIndex] != 0 else {
                continue
            }

            var points: [PosePoint?] = []

            for nodeIndex in 0..<nodeCount {
                let pointIndex = animalIndex * nodeCount + nodeIndex
                let coordinateIndex = pointIndex * 2

                let x = coordinates[coordinateIndex]
                let y = coordinates[coordinateIndex + 1]
                let score = scores[pointIndex]

                // Preserve the node's position even when its prediction is missing.
                guard x.isFinite, y.isFinite, score.isFinite else {
                    points.append(nil)
                    continue
                }

                let point = PosePoint(
                    x: Double(x),
                    y: Double(y),
                    score: Double(score)
                )

                points.append(point)
            }

            instances.append(
                PoseInstance(points: points)
            )
        }

       // Ensure all nodes are labeled
        guard skeleton.nodeNames.count == nodeCount else {
            throw DecodeError.unexpectedShape
        }
        
        return PosePrediction(
            imageWidth: input.width,
            imageHeight: input.height,
            nodeNames: skeleton.nodeNames,
            edges: skeleton.edges,
            instances: instances
        )
        
        
    }
    
    
}
