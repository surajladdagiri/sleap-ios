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
                    
                    
                    
                    for (index, instance) in prediction.instances.enumerated() {
                        let color = colors[index % colors.count]
                        
                        
                        
                        //Add in edges
                        for edge in prediction.edges {
                            //ensure valid edges
                            guard edge.count == 2 else{
                                continue
                            }
                            
                            
                            let sourceIndex = edge[0]
                            let destinationIndex = edge[1]
                            
                            //Get locations of source and destination points and ensure validity
                            guard instance.points.indices.contains(sourceIndex),
                                instance.points.indices.contains(destinationIndex),
                                  let source = instance.points[sourceIndex],
                                  let destination = instance.points[destinationIndex],
                                  source.x.isFinite,
                                  source.y.isFinite,
                                  destination.x.isFinite,
                                  destination.y.isFinite else {
                                continue
                            }
                            
                            
                            //Map points back to image
                            let start = CGPoint(
                                x: CGFloat(source.x) * scaleX,
                                y: CGFloat(source.y) * scaleY
                            )
                            let end = CGPoint(
                                x: CGFloat(destination.x) * scaleX,
                                y: CGFloat(destination.y) * scaleY
                            )
                            
                            var line = Path()
                            line.move(to: start)
                            line.addLine(to: end)
                            
                            context.stroke(
                                line,
                                with: .color(color),
                                style: StrokeStyle(
                                    lineWidth: 2,
                                    lineCap: .round
                                )
                            )
                        }

                        
                        
                        
                        
                        
                        //Add in points
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


