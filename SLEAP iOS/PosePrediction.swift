//
//  PosePrediction.swift
//  SLEAP iOS
//
//  Created by Suraj Laddagiri  on 9/24/26.
//

struct PosePoint: Decodable, Sendable {
    let x: Double
    let y: Double
    let score: Double
}

struct PoseInstance: Decodable, Sendable {
    let points: [PosePoint?]
}

struct PoseSkeleton: Decodable, Sendable {
    let nodeNames: [String]
    let edges: [[Int]]

    enum CodingKeys: String, CodingKey {
        case nodeNames = "node_names"
        case edges = "edge_inds"
    }
}

struct PosePrediction: Decodable, Sendable {
    let imageWidth: Int
    let imageHeight: Int
    let nodeNames: [String]
    let edges: [[Int]]
    let instances: [PoseInstance]
}
