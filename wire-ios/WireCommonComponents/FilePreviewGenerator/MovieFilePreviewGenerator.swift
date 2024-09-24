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
import UIKit

struct MovieFilePreviewGenerator: FilePreviewGenerator {

    let thumbnailSize: CGSize

    func supportsPreviewGenerationForFile(at url: URL) -> Bool {
        guard let uniformType = url.uniformType else { return false }
        return AVURLAsset.wr_isAudioVisualUniformType(uniformType)
    }

    func generatePreviewForFile(at url: URL) throws -> UIImage {

        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        let timeTolerance = CMTimeMakeWithSeconds(1, preferredTimescale: 60)

        generator.requestedTimeToleranceBefore = timeTolerance
        generator.requestedTimeToleranceAfter = timeTolerance
        let time = CMTimeMakeWithSeconds(asset.duration.seconds * 0.1, preferredTimescale: 60)
        var actualTime = CMTime.zero
        let cgImage = try? generator.copyCGImage(at: time, actualTime: &actualTime)
        guard let cgImage, let colorSpace = cgImage.colorSpace else {
            throw Error.failedToCreatePreview
        }

        let bitsPerComponent = cgImage.bitsPerComponent
        let bitmapInfo = cgImage.bitmapInfo
        let width = cgImage.width
        let height = cgImage.height
        let renderRect = AspectFitRectInRect(
            CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)),
            into: CGRect(x: 0, y: 0, width: thumbnailSize.width, height: thumbnailSize.height)
        )
        let context = CGContext(
            data: nil,
            width: Int(renderRect.size.width),
            height: Int(renderRect.size.height),
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: Int(renderRect.size.width) * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        )
        guard let context else {
            throw Error.failedToCreatePreview
        }

        context.interpolationQuality = CGInterpolationQuality.high
        context.draw(cgImage, in: renderRect)
        if let cgImage = context.makeImage() {
            return .init(cgImage: cgImage)
        } else {
            throw Error.failedToCreatePreview
        }
    }

    // MARK: -

    enum Error: Swift.Error {
        case failedToCreatePreview
    }
}

private func ScaleToAspectFitRectInRect(_ fit: CGRect, into: CGRect) -> CGFloat {

    guard fit.width != 0, fit.height != 0 else { return 1 }

    // first try to match width
    let s = into.width / fit.width

    // if we scale the height to make the widths equal, does it still fit?
    if fit.height * s <= into.height {
        return s
    }

    // no, match height instead
    return into.height / fit.height
}

private func AspectFitRectInRect(_ fit: CGRect, into: CGRect) -> CGRect {
    let s = ScaleToAspectFitRectInRect(fit, into: into)
    let w = fit.width * s
    let h = fit.height * s
    return CGRect(x: 0, y: 0, width: w, height: h)
}
