//
//  PoseRenderer.swift
//  SLEAP iOS
//
//  Created by Suraj Laddagiri  on 9/24/26.
//

import SwiftUI
import UIKit



struct PoseRenderer{
    
    //isolate UI updates
    @MainActor
    func render(image: UIImage) -> UIImage?{
        let content = Image(uiImage: image)
            .resizable()
            .frame(
                width: image.size.width,
                height: image.size.height
            )
            .overlay {
                Canvas { context, size in
                    let radius: CGFloat = 10
                    
                    let dot = CGRect(
                        x: size.width / 2 - radius,
                        y: size.height/2 - radius,
                        width: radius * 2,
                        height: radius * 2
                    )
                    
                    context.fill(
                        Path(ellipseIn: dot),
                        with: .color(.red)
                    )
                    
                }
            }
        
        let renderer = ImageRenderer(content: content)
        renderer.scale = image.scale
        
        
        
        return renderer.uiImage
    }
}


