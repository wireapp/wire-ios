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

protocol FilePreviewGenerator {

    var callbackQueue: OperationQueue { get }
    var thumbnailSize: CGSize { get }

    func supportsPreviewGenerationForFile(at url: URL, uniformType: UTType) -> Bool
    func generatePreview(for file: URL, uniformType: UTType, completion: @escaping (UIImage?) -> Void)
    // TODO: remove
    func canGeneratePreviewForFile(_ fileURL: URL, UTI: String) -> Bool
    func generatePreview(_ fileURL: URL, UTI: String, completion: @escaping (UIImage?) -> Void)
}

// TODO: remove
extension FilePreviewGenerator {

    func supportsPreviewGenerationForFile(at url: URL, uniformType: UTType) -> Bool {
        canGeneratePreviewForFile(url, UTI: uniformType.identifier)
    }

    func generatePreview(for file: URL, uniformType: UTType, completion: @escaping (UIImage?) -> Void) {
        generatePreview(file, UTI: uniformType.identifier, completion: completion)
    }
}
