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


import Foundation
import MobileCoreServices
import ImageIO
import AVFoundation
import CoreGraphics

extension NSURL {
    public func UTI() -> String {
        guard let pathExtension = self.pathExtension,
                let UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension, .None),
                let UTIString = UTI.takeUnretainedValue() as String? else {
                    return kUTTypeItem as String
        }
        return UTIString
    }
}

func ScaleToAspectFitRectInRect(fit: CGRect, into: CGRect) -> CGFloat
{
    // first try to match width
    let s = CGRectGetWidth(into) / CGRectGetWidth(fit)
    // if we scale the height to make the widths equal, does it still fit?
    if (CGRectGetHeight(fit) * s <= CGRectGetHeight(into)) {
        return s
    }
    // no, match height instead
    return CGRectGetHeight(into) / CGRectGetHeight(fit)
}

func AspectFitRectInRect(fit: CGRect, into: CGRect) -> CGRect
{
    let s = ScaleToAspectFitRectInRect(fit, into: into);
    let w = CGRectGetWidth(fit) * s;
    let h = CGRectGetHeight(fit) * s;
    return CGRectMake(0, 0, w, h);
}

@objc public protocol FilePreviewGenerator {
    var callbackQueue: NSOperationQueue { get }
    var thumbnailSize: CGSize { get }
    func canGeneratePreviewForFile(fileURL: NSURL, UTI: String) -> Bool
    func generatePreview(fileURL: NSURL, UTI: String, completion: (UIImage?) -> ())
}

@objc public class SharedPreviewGenerator: NSObject {
    static var generator: AggregateFilePreviewGenerator = {
        let resultQueue = NSOperationQueue.mainQueue()
        let thumbnailSizeDefault = CGSizeMake(120, 120)
        let thumbnailSizeVideo = CGSizeMake(640, 480)
        
        let imageGenerator = ImageFilePreviewGenerator(callbackQueue: resultQueue, thumbnailSize: thumbnailSizeDefault)
        let movieGenerator = MovieFilePreviewGenerator(callbackQueue: resultQueue, thumbnailSize: thumbnailSizeVideo)
        let pdfGenerator = PDFFilePreviewGenerator(callbackQueue: resultQueue, thumbnailSize: thumbnailSizeDefault)
        
        return AggregateFilePreviewGenerator(subGenerators: [imageGenerator, movieGenerator, pdfGenerator], callbackQueue: resultQueue, thumbnailSize: thumbnailSizeDefault)
    }()
}

@objc public class AggregateFilePreviewGenerator: NSObject, FilePreviewGenerator {
    let subGenerators: [FilePreviewGenerator]
    public let thumbnailSize: CGSize
    public let callbackQueue: NSOperationQueue
    
    init(subGenerators: [FilePreviewGenerator], callbackQueue: NSOperationQueue, thumbnailSize: CGSize) {
        self.callbackQueue = callbackQueue
        self.thumbnailSize = thumbnailSize
        self.subGenerators = subGenerators
        super.init()
    }
    
    public func canGeneratePreviewForFile(fileURL: NSURL, UTI uti: String) -> Bool {
        return self.subGenerators.filter {
            $0.canGeneratePreviewForFile(fileURL, UTI:uti)
        }.count > 0
    }
    
    public func generatePreview(fileURL: NSURL, UTI uti: String, completion: (UIImage?) -> ()) {
        guard let generator = self.subGenerators.filter({
            $0.canGeneratePreviewForFile(fileURL, UTI: uti)
        }).first else {
            completion(.None)
            return
        }
        
        return generator.generatePreview(fileURL, UTI: uti, completion: completion)
    }
}


@objc public class ImageFilePreviewGenerator: NSObject, FilePreviewGenerator {
    public let thumbnailSize: CGSize
    public let callbackQueue: NSOperationQueue
    
    init(callbackQueue: NSOperationQueue, thumbnailSize: CGSize) {
        self.thumbnailSize = thumbnailSize
        self.callbackQueue = callbackQueue
        super.init()
    }
    
    public func canGeneratePreviewForFile(fileURL: NSURL, UTI uti: String) -> Bool {
        return UTTypeConformsTo(uti, kUTTypeImage)
    }
    
    public func generatePreview(fileURL: NSURL, UTI uti: String, completion: (UIImage?) -> ()) {
        var result: UIImage? = .None
        
        defer {
            self.callbackQueue.addOperationWithBlock { 
                completion(result)
            }
        }
        
        guard let src = CGImageSourceCreateWithURL(fileURL, nil) else {
            return
        }
        
        let options: [NSObject: AnyObject] = [
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: max(self.thumbnailSize.width, self.thumbnailSize.height)
        ]
        
        guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(src, 0, options) else {
            return
        }
        
        result = UIImage(CGImage: thumbnail)
    }
}


@objc public class MovieFilePreviewGenerator: NSObject, FilePreviewGenerator {
    public let thumbnailSize: CGSize
    public let callbackQueue: NSOperationQueue
    
    init(callbackQueue: NSOperationQueue, thumbnailSize: CGSize) {
        self.thumbnailSize = thumbnailSize
        self.callbackQueue = callbackQueue
        super.init()
    }
    
    public func canGeneratePreviewForFile(fileURL: NSURL, UTI uti: String) -> Bool {
        return AVURLAsset.wr_isAudioVisualUTI(uti)
    }
    
    public func generatePreview(fileURL: NSURL, UTI uti: String, completion: (UIImage?) -> ()) {
        var result: UIImage? = .None
        
        defer {
            self.callbackQueue.addOperationWithBlock {
                completion(result)
            }
        }
        
        let asset = AVURLAsset(URL: fileURL)
        
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        let timeTolerance = CMTimeMakeWithSeconds(1, 60)

        generator.requestedTimeToleranceBefore = timeTolerance
        generator.requestedTimeToleranceAfter = timeTolerance
        
        let time = CMTimeMakeWithSeconds(asset.duration.seconds * 0.1, 60)
        var actualTime = kCMTimeZero
        guard let cgImage = try? generator.copyCGImageAtTime(time, actualTime:&actualTime) else {
            return
        }
        
        let bitsPerComponent = CGImageGetBitsPerComponent(cgImage)
        let colorSpace = CGImageGetColorSpace(cgImage)
        let bitmapInfo = CGImageGetBitmapInfo(cgImage)
        
        let width = CGImageGetWidth(cgImage)
        let height = CGImageGetHeight(cgImage)
        
        let renderRect = AspectFitRectInRect(CGRectMake(0, 0, CGFloat(width), CGFloat(height)), into: CGRectMake(0, 0, self.thumbnailSize.width, self.thumbnailSize.height))
        
        let context = CGBitmapContextCreate(nil, Int(renderRect.size.width), Int(renderRect.size.height), bitsPerComponent, Int(renderRect.size.width) * 4, colorSpace, bitmapInfo.rawValue)
        
        CGContextSetInterpolationQuality(context, CGInterpolationQuality.High)
        CGContextDrawImage(context, renderRect, cgImage)
        
        result = CGBitmapContextCreateImage(context).flatMap { UIImage(CGImage: $0) }
    }
    
}


@objc public class PDFFilePreviewGenerator: NSObject, FilePreviewGenerator {
    public let thumbnailSize: CGSize
    public let callbackQueue: NSOperationQueue
    
    init(callbackQueue: NSOperationQueue, thumbnailSize: CGSize) {
        self.thumbnailSize = thumbnailSize
        self.callbackQueue = callbackQueue
        super.init()
    }
    
    public func canGeneratePreviewForFile(fileURL: NSURL, UTI uti: String) -> Bool {
        return UTTypeConformsTo(uti, kUTTypePDF)
    }
    
    public func generatePreview(fileURL: NSURL, UTI uti: String, completion: (UIImage?) -> ()) {
        var result: UIImage? = .None
        
        defer {
            self.callbackQueue.addOperationWithBlock {
                completion(result)
            }
        }
        
        UIGraphicsBeginImageContext(thumbnailSize)
        let pdfRef = CGPDFDocumentCreateWithProvider(CGDataProviderCreateWithURL(fileURL))
        let pageRef = CGPDFDocumentGetPage(pdfRef, 1)
        
        let contextRef = UIGraphicsGetCurrentContext()
        CGContextSetAllowsAntialiasing(contextRef, true)
        
        let cropBox = CGPDFPageGetBoxRect(pageRef, CGPDFBox.CropBox)
        let xScale = self.thumbnailSize.width / cropBox.size.width
        let yScale = self.thumbnailSize.height / cropBox.size.height
        let scaleToApply = xScale < yScale ? xScale : yScale
        
        CGContextConcatCTM(contextRef, CGAffineTransformMakeScale(scaleToApply, scaleToApply))
        CGContextDrawPDFPage(contextRef, pageRef)

        result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }
}
