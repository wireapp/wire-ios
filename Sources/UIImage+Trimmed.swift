//
//  UIImage+Trimmed.swift
//  Canvas
//
//  Created by Jacob on 25/10/16.
//  Copyright © 2016 Wire GmbH. All rights reserved.
//

import Foundation

public extension UIImage {
    
    var imageWithAlphaTrimmed : UIImage {
        let originalSize = self.size
        
        var minX = Int.max
        var maxX = Int.min
        var minY = Int.max
        var maxY = Int.min
        var nonAlphaBounds = CGRect.zero
        var trimmedImage : UIImage = self
        
        UIGraphicsBeginImageContextWithOptions(originalSize, false, scale)
        
        draw(at: CGPoint.zero)
        
        if let context = UIGraphicsGetCurrentContext(), var pixelData = context.data?.assumingMemoryBound(to: UInt32.self) {
            
            let alignment = (8 - (context.width % 8)) % 8
            
            for y in 0..<context.height * 1 {
                for x in 0..<context.width * 1 {
                    let alpha = UInt8((pixelData.pointee >> 24) & 255)
                    
                    if alpha > 0 {
                        minX = min(x, minX)
                        maxX = max(x, maxX)
                        minY = min(y, minY)
                        maxY = max(y, maxY)
                    }
                    
                    pixelData = pixelData.successor()
                }
                pixelData = pixelData.advanced(by: alignment)
            }
            
            nonAlphaBounds = CGRect(x: Double(minX) / 2.0, y: Double(minY) / 2.0, width: Double(maxX - minX) / 2.0, height: Double(maxY - minY) / 2.0)
        }
        
        UIGraphicsEndImageContext()
        
        UIGraphicsBeginImageContextWithOptions(nonAlphaBounds.size, false, scale)
        
        draw(at: CGPoint(x: -nonAlphaBounds.origin.x, y: -nonAlphaBounds.origin.y))
        
        if let image = UIGraphicsGetImageFromCurrentImageContext() {
            trimmedImage = image
        }
        
        UIGraphicsEndImageContext()
        
        return trimmedImage
    }
    
}
