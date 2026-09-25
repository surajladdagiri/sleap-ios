//
//  PoseEstimator.swift
//  SLEAP iOS
//
//  Created by Suraj Laddagiri  on 9/24/26.
//

struct PoseModelInterface: Sendable {
    let inputNames: [String]
    let outputNames: [String]
}

protocol PoseEstimator: Actor {
    func modelInterface() async throws -> PoseModelInterface
    
    func predict(input: PoseInput, skeleton: PoseSkeleton) async throws -> PosePrediction
}
