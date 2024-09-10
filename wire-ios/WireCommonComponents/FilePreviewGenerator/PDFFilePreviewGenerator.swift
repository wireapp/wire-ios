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

import UIKit
import UniformTypeIdentifiers

// TODO: remove import
import CoreServices

struct PDFFilePreviewGenerator: FilePreviewGenerator {

    let thumbnailSize: CGSize
    let callbackQueue: OperationQueue

    @available(*, deprecated, message: "TODO: delete")
    func canGeneratePreviewForFile(_ fileURL: URL, UTI uti: String) -> Bool {
        UTTypeConformsTo(uti as CFString, kUTTypePDF)
    }

    func generatePreview(_ fileURL: URL, type: UTType, completion: @escaping (UIImage?) -> Void) {
        generatePreview(fileURL, UTI: type.identifier, completion: completion)
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
        let xScale = self.thumbnailSize.width / cropBox.size.width
        let yScale = self.thumbnailSize.height / cropBox.size.height
        let scaleToApply = xScale < yScale ? xScale : yScale
        contextRef.concatenate(CGAffineTransform(scaleX: scaleToApply, y: scaleToApply))
        contextRef.drawPDFPage(pageRef)

        result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }
}
