//
//  Preprocessor.swift
//  SLEAP iOS
//
//  Created by Suraj Laddagiri  on 9/24/26.
//

import UIKit

struct PoseInput: Sendable {
    let pixels: [UInt8]
    let width: Int
    let height: Int
}

struct Preprocessor{
    func prepare(image: UIImage) -> PoseInput? {
        guard let cgImage = image.cgImage else {
            return nil
        }
        
        let width = cgImage.width
        let height = cgImage.height
        
        //Create empty buffer
        var pixels = [UInt8](repeating: 0, count: width * height)
        
        let succeeded = pixels.withUnsafeMutableBytes{buffer -> Bool in
            guard let context = CGContext(
                data: buffer.baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width,
                space: CGColorSpaceCreateDeviceGray(),
                bitmapInfo: CGImageAlphaInfo.none.rawValue
            ) else {
                return false
            }
            
            
            context.draw(
                cgImage,
                in: CGRect(
                    x: 0,
                    y: 0,
                    width: CGFloat(width),
                    height: CGFloat(height)
                )
            )
            return true
            
        }
        
        
        guard succeeded else{
            return nil
        }
        
        return PoseInput(pixels: pixels, width: width, height: height)
    }
}
