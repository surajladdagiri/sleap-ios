//
//  ContentView.swift
//  SLEAP iOS
//
//  Created by Suraj Laddagiri  on 9/23/26.
//

import SwiftUI
import UIKit

struct ContentView: View {
    private static let OriginalImage = UIImage(named: "reference.png")
    private static let OriginalRenderedImage = UIImage(named: "reference_overlay.png")
    @State private var ErrorMessage: String = "Image could not be Loaded"
    @State private var DisplayedImage: UIImage? = ContentView.OriginalImage
    
    
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

            HStack(spacing: 16) {
                Button("Render") {
                    
                    guard let url = Bundle.main.url(
                        forResource: "reference",
                        withExtension: "json"
                    ) else {
                        ErrorMessage = "reference.json was not found."
                        DisplayedImage = nil
                        return
                    }
                    
                    
                    do {
                        let data = try Data(contentsOf: url)
                        
                        let prediction = try JSONDecoder().decode(
                            PosePrediction.self,
                            from: data
                        )
                        
                    } catch {
                        ErrorMessage = "Unable to decode JSON"
                        DisplayedImage = nil
                    }
                    
                    
                    guard let original = Self.OriginalImage else {
                        DisplayedImage = nil
                        return
                    }
                    
                    DisplayedImage = PoseRenderer().render(image: original)
                }
                Button("Reference"){
                    DisplayedImage = Self.OriginalRenderedImage
                }

                Button("Reset") {
                    DisplayedImage = Self.OriginalImage
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
