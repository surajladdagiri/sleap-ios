//
//  PosePrediction.swift
//  SLEAP iOS
//
//  Created by Suraj Laddagiri  on 9/24/26.
//

struct PosePoint: Decodable {
    let x: Double
    let y: Double
    let score: Double
}

struct PoseInstance: Decodable {
    let points: [PosePoint?]
}

struct PosePrediction: Decodable {
    let imageWidth: Int
    let imageHeight: Int
    let nodeNames: [String]
    let edges: [[Int]]
    let instances: [PoseInstance]
}
