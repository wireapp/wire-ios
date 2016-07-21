// 
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
// 
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
// 


import UIKit
import ImageIO

extension UIImage {
    
    class func loadPreviewForImageWithURL(imageURL: NSURL, maxPixelSize previewImagePixelSize:Int, completion:(previewImage: UIImage?) -> Void) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            guard let imageSource = CGImageSourceCreateWithURL(imageURL, nil),
                imagePropertiesRef = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil)
                else { return }
            
            let imageProperties = imagePropertiesRef as NSDictionary
            
            guard let imageWidth = (imageProperties[String(kCGImagePropertyPixelWidth)] as? NSNumber)?.floatValue,
                imageHeight = (imageProperties[String(kCGImagePropertyPixelHeight)] as? NSNumber)?.floatValue
                else { return }

            
            var orientation = UIImageOrientation.Up
            if let imageCGOrientation = (imageProperties[String(kCGImagePropertyOrientation)] as? NSNumber)?.unsignedIntValue,
                imagePropertyOrientation = CGImagePropertyOrientation(rawValue: imageCGOrientation),
                imageUIOrientation = UIImageOrientation.fromCGImageOrientation(imagePropertyOrientation) {
                    orientation = imageUIOrientation
            }
            
            let aspectRatio = (imageWidth > imageHeight) ? imageWidth / imageHeight : imageHeight / imageWidth
            let maxPixelSize = aspectRatio * Float(previewImagePixelSize)
            
            let options: [NSObject: AnyObject] =
            [
                kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
                kCGImageSourceCreateThumbnailFromImageIfAbsent: true,
            ]
            
            guard let thumbnailCGImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options)
                else { return }
            
            let thumbnailImage = UIImage(CGImage: thumbnailCGImage, scale:1.0, orientation: orientation)
            dispatch_async(dispatch_get_main_queue()) {
                completion(previewImage: thumbnailImage)
            }
        }
    }
}

extension UIImageOrientation {
    static func fromCGImageOrientation(orientation:CGImagePropertyOrientation) -> UIImageOrientation? {
        let imageOrientationMapping: Dictionary<UInt32, UIImageOrientation> =
        [
            CGImagePropertyOrientation.Up.rawValue           : UIImageOrientation.Up,
            CGImagePropertyOrientation.UpMirrored.rawValue   : UIImageOrientation.UpMirrored,
            CGImagePropertyOrientation.Down.rawValue         : UIImageOrientation.Down,
            CGImagePropertyOrientation.DownMirrored.rawValue : UIImageOrientation.DownMirrored,
            CGImagePropertyOrientation.LeftMirrored.rawValue : UIImageOrientation.RightMirrored,
            CGImagePropertyOrientation.Right.rawValue        : UIImageOrientation.Right,
            CGImagePropertyOrientation.RightMirrored.rawValue: UIImageOrientation.LeftMirrored,
            CGImagePropertyOrientation.Left.rawValue         : UIImageOrientation.Left,
        ]
        return imageOrientationMapping[orientation.rawValue]
    }
}
