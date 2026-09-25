//
//  ContentView.swift
//  SLEAP iOS
//
//  Created by Suraj Laddagiri  on 9/23/26.
//

import SwiftUI
import UIKit

struct ContentView: View {
    var body: some View {
        NavigationStack{
            VStack(spacing: 20) {
                NavigationLink{
                    RenderTestView()
                } label: {
                    Text("Renderer Test")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                
                NavigationLink{
                    PredictionTestView()
                } label: {
                    Text("Prediction Test")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                
                NavigationLink{
                    VideoTestView()
                } label: {
                    Text("Video Test")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}
