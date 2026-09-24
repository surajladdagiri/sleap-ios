//
//  ContentView.swift
//  SLEAP iOS
//
//  Created by Suraj Laddagiri  on 9/23/26.
//

import SwiftUI
import UIKit

struct ContentView: View {
    private static let originalImage = UIImage(named: "reference.png")
    private static let originalRenderedImage = UIImage(named: "reference_overlay.png")
    @State private var displayedImage: UIImage? = ContentView.originalImage
    
    
    var body: some View {
        VStack(spacing: 20) {
            
            if let displayedImage{
                Image(uiImage: displayedImage)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(Color.green, lineWidth: 4)
                    )
            }else {
                Text("Image could not be loaded")
            }

            HStack(spacing: 16) {
                Button("Draw Points") {
                        
                }
                Button("Reference"){
                    displayedImage = Self.originalRenderedImage
                }

                Button("Reset") {
                    displayedImage = Self.originalImage
                }
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
