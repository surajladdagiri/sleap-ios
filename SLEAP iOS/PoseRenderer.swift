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
    func render(image: UIImage, prediction: PosePrediction) -> UIImage?{
        let content = Image(uiImage: image)
            .resizable()
            .frame(
                width: image.size.width,
                height: image.size.height
            )
            .overlay {
                Canvas { context, size in
                    let scaleX = size.width / CGFloat(prediction.imageWidth)
                    let scaleY = size.height / CGFloat(prediction.imageHeight)
                    
                    let colors: [Color] = [.cyan, .orange]
                    let radius: CGFloat = 3
                    
                   
                    
                    
                    
                    
                    //Add in the points
                    for (index, instance) in prediction.instances.enumerated() {
                        let color = colors[index % colors.count]
                        
                        //check if point is valid
                        for optionalPoint in instance.points {
                            guard let point = optionalPoint,
                                  point.x.isFinite,
                                  point.y.isFinite else {
                                continue
                            }
                            
                            //Map points back to the image
                            let x = CGFloat(point.x) * scaleX
                            let y = CGFloat(point.y) * scaleY
                            
                            //Determine bounds of the points
                            let bounds = CGRect(
                                x: x - radius,
                                y: y - radius,
                                width: radius * 2.0,
                                height: radius * 2.0
                            )
                            
                            //Draw in points
                            context.fill(
                                Path(ellipseIn: bounds),
                                with: .color(color)
                            )
                        }
                    }
                }
            }
        
        let renderer = ImageRenderer(content: content)
        renderer.scale = image.scale
        
        
        
        return renderer.uiImage
    }
}


