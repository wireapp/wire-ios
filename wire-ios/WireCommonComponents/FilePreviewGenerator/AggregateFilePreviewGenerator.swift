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

struct AggregateFilePreviewGenerator: FilePreviewGenerator {

    let subGenerators: [FilePreviewGenerator]
    let thumbnailSize: CGSize
    let callbackQueue: OperationQueue

    func canGeneratePreviewForFile(_ fileURL: URL, UTI uti: String) -> Bool {
        !subGenerators.filter {
            $0.canGeneratePreviewForFile(fileURL, UTI: uti)
        }.isEmpty
    }

    func generatePreview(_ fileURL: URL, UTI uti: String, completion: @escaping (UIImage?) -> Void) {

        guard let generator = subGenerators.filter({
            $0.canGeneratePreviewForFile(fileURL, UTI: uti)
        }).first else {
            return completion(.none)
        }

        return generator.generatePreview(fileURL, UTI: uti, completion: completion)
    }
}
