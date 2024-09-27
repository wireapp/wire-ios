//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

import AVFoundation
import CoreGraphics
import ImageIO
import MobileCoreServices
import UIKit

extension URL {
    public func UTI() -> String {
        guard let UTI = UTTypeCreatePreferredIdentifierForTag(
            kUTTagClassFilenameExtension,
            pathExtension as CFString,
            .none
        ) else {
            return kUTTypeItem as String
        }
        return UTI.takeRetainedValue() as String
    }
}

extension NSURL {
    var UTI: String {
        (self as URL).UTI()
    }
}

func ScaleToAspectFitRectInRect(_ fit: CGRect, into: CGRect) -> CGFloat {
    guard fit.width != 0, fit.height != 0 else {
        return 1
    }
    // first try to match width
    let s = into.width / fit.width
    // if we scale the height to make the widths equal, does it still fit?
    if fit.height * s <= into.height {
        return s
    }
    // no, match height instead
    return into.height / fit.height
}

func AspectFitRectInRect(_ fit: CGRect, into: CGRect) -> CGRect {
    let s = ScaleToAspectFitRectInRect(fit, into: into)
    let w = fit.width * s
    let h = fit.height * s
    return CGRect(x: 0, y: 0, width: w, height: h)
}

// MARK: - FilePreviewGenerator

protocol FilePreviewGenerator {
    var callbackQueue: OperationQueue { get }
    var thumbnailSize: CGSize { get }
    func canGeneratePreviewForFile(_ fileURL: URL, UTI: String) -> Bool
    func generatePreview(_ fileURL: URL, UTI: String, completion: @escaping (UIImage?) -> Void)
}

// MARK: - SharedPreviewGenerator

final class SharedPreviewGenerator: NSObject {
    static var generator: AggregateFilePreviewGenerator = {
        let resultQueue = OperationQueue.main
        let thumbnailSizeDefault = CGSize(width: 120, height: 120)
        let thumbnailSizeVideo = CGSize(width: 640, height: 480)
        let imageGenerator = ImageFilePreviewGenerator(callbackQueue: resultQueue, thumbnailSize: thumbnailSizeDefault)
        let movieGenerator = MovieFilePreviewGenerator(callbackQueue: resultQueue, thumbnailSize: thumbnailSizeVideo)
        let pdfGenerator = PDFFilePreviewGenerator(callbackQueue: resultQueue, thumbnailSize: thumbnailSizeDefault)
        return AggregateFilePreviewGenerator(
            subGenerators: [imageGenerator, movieGenerator, pdfGenerator],
            callbackQueue: resultQueue,
            thumbnailSize: thumbnailSizeDefault
        )
    }()
}

// MARK: - AggregateFilePreviewGenerator

final class AggregateFilePreviewGenerator: NSObject, FilePreviewGenerator {
    let subGenerators: [FilePreviewGenerator]
    let thumbnailSize: CGSize
    let callbackQueue: OperationQueue
    init(subGenerators: [FilePreviewGenerator], callbackQueue: OperationQueue, thumbnailSize: CGSize) {
        self.callbackQueue = callbackQueue
        self.thumbnailSize = thumbnailSize
        self.subGenerators = subGenerators
        super.init()
    }

    func canGeneratePreviewForFile(_ fileURL: URL, UTI uti: String) -> Bool {
        !subGenerators.filter {
            $0.canGeneratePreviewForFile(fileURL, UTI: uti)
        }.isEmpty
    }

    func generatePreview(_ fileURL: URL, UTI uti: String, completion: @escaping (UIImage?) -> Void) {
        guard let generator = subGenerators.filter({
            $0.canGeneratePreviewForFile(fileURL, UTI: uti)
        }).first else {
            completion(.none)
            return
        }
        return generator.generatePreview(fileURL, UTI: uti, completion: completion)
    }
}

// MARK: - ImageFilePreviewGenerator

final class ImageFilePreviewGenerator: NSObject, FilePreviewGenerator {
    let thumbnailSize: CGSize
    let callbackQueue: OperationQueue
    init(callbackQueue: OperationQueue, thumbnailSize: CGSize) {
        self.thumbnailSize = thumbnailSize
        self.callbackQueue = callbackQueue
        super.init()
    }

    func canGeneratePreviewForFile(_ fileURL: URL, UTI uti: String) -> Bool {
        UTType(uti)?.conforms(to: UTType.image) ?? false
    }

    func generatePreview(_ fileURL: URL, UTI: String, completion: @escaping (UIImage?) -> Void) {
        var result: UIImage? = .none
        defer {
            self.callbackQueue.addOperation {
                completion(result)
            }
        }
        guard let src = CGImageSourceCreateWithURL(fileURL as CFURL, nil) else {
            return
        }
        let options: [AnyHashable: Any] = [
            kCGImageSourceCreateThumbnailWithTransform as AnyHashable: true,
            kCGImageSourceCreateThumbnailFromImageAlways as AnyHashable: true,
            kCGImageSourceThumbnailMaxPixelSize as AnyHashable: max(
                thumbnailSize.width,
                thumbnailSize.height
            ),
        ]
        guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(src, 0, options as CFDictionary?) else {
            return
        }
        result = UIImage(cgImage: thumbnail)
    }
}

// MARK: - MovieFilePreviewGenerator

final class MovieFilePreviewGenerator: NSObject, FilePreviewGenerator {
    let thumbnailSize: CGSize
    let callbackQueue: OperationQueue
    init(callbackQueue: OperationQueue, thumbnailSize: CGSize) {
        self.thumbnailSize = thumbnailSize
        self.callbackQueue = callbackQueue
        super.init()
    }

    func canGeneratePreviewForFile(_ fileURL: URL, UTI uti: String) -> Bool {
        AVURLAsset.wr_isAudioVisualUTI(uti)
    }

    func generatePreview(_ fileURL: URL, UTI: String, completion: @escaping (UIImage?) -> Void) {
        var result: UIImage? = .none
        defer {
            self.callbackQueue.addOperation {
                completion(result)
            }
        }
        let asset = AVURLAsset(url: fileURL)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        let timeTolerance = CMTimeMakeWithSeconds(1, preferredTimescale: 60)

        generator.requestedTimeToleranceBefore = timeTolerance
        generator.requestedTimeToleranceAfter = timeTolerance
        let time = CMTimeMakeWithSeconds(asset.duration.seconds * 0.1, preferredTimescale: 60)
        var actualTime = CMTime.zero
        guard let cgImage = try? generator.copyCGImage(at: time, actualTime: &actualTime),
              let colorSpace = cgImage.colorSpace else {
            return
        }
        let bitsPerComponent = cgImage.bitsPerComponent
        let bitmapInfo = cgImage.bitmapInfo
        let width = cgImage.width
        let height = cgImage.height
        let renderRect = AspectFitRectInRect(
            CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)),
            into: CGRect(
                x: 0,
                y: 0,
                width: thumbnailSize.width,
                height: thumbnailSize.height
            )
        )
        guard let context = CGContext(
            data: nil,
            width: Int(renderRect.size.width),
            height: Int(renderRect.size.height),
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: Int(renderRect.size.width) * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else {
            return
        }
        context.interpolationQuality = CGInterpolationQuality.high
        context.draw(cgImage, in: renderRect)
        result = context.makeImage().flatMap { UIImage(cgImage: $0) }
    }
}

// MARK: - PDFFilePreviewGenerator

public final class PDFFilePreviewGenerator: NSObject, FilePreviewGenerator {
    let thumbnailSize: CGSize
    let callbackQueue: OperationQueue
    public init(callbackQueue: OperationQueue, thumbnailSize: CGSize) {
        self.thumbnailSize = thumbnailSize
        self.callbackQueue = callbackQueue
        super.init()
    }

    func canGeneratePreviewForFile(_ fileURL: URL, UTI uti: String) -> Bool {
        UTTypeConformsTo(uti as CFString, kUTTypePDF)
    }

    func generatePreview(_ fileURL: URL, UTI: String, completion: @escaping (UIImage?) -> Void) {
        var result: UIImage? = .none
        defer {
            self.callbackQueue.addOperation {
                completion(result)
            }
        }
        UIGraphicsBeginImageContext(thumbnailSize)
        guard let dataProvider = CGDataProvider(url: fileURL as CFURL),
              let pdfRef = CGPDFDocument(dataProvider),
              let pageRef = pdfRef.page(at: 1),
              let contextRef = UIGraphicsGetCurrentContext() else {
            return
        }
        contextRef.setAllowsAntialiasing(true)
        let cropBox = pageRef.getBoxRect(CGPDFBox.cropBox)
        guard cropBox.size.width != 0,
              cropBox.size.width < 16384,
              cropBox.size.height != 0,
              cropBox.size.height < 16384
        else {
            return
        }
        let xScale = thumbnailSize.width / cropBox.size.width
        let yScale = thumbnailSize.height / cropBox.size.height
        let scaleToApply = xScale < yScale ? xScale : yScale
        contextRef.concatenate(CGAffineTransform(scaleX: scaleToApply, y: scaleToApply))
        contextRef.drawPDFPage(pageRef)

        result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }
}
