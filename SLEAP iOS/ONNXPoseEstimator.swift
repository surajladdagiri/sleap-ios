//
//  ONNXPoseEstimator.swift
//  SLEAP iOS
//
//  Created by Suraj Laddagiri  on 9/24/26.
//

import Foundation
import OnnxRuntimeBindings

actor ONNXPoseEstimator: PoseEstimator {
    private let modelURL: URL
    private var environment: ORTEnv?
    private var session: ORTSession?
    
    init(modelURL: URL) {
        self.modelURL = modelURL
    }
    
    
    private func loadSession(force: Bool = false) throws -> ORTSession {
        
        //check if a session is already established
        if let session, !force {
            return session
        }
        
        let environment = try ORTEnv(loggingLevel: .warning)
        
        let session = try ORTSession(env: environment, modelPath: modelURL.path, sessionOptions: nil)
        
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
    
}
