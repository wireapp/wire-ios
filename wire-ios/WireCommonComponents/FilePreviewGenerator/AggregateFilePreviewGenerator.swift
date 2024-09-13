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

struct AggregateFilePreviewGenerator: FilePreviewGenerator {

    let generators: [FilePreviewGenerator]
    let thumbnailSize: CGSize

    func supportsPreviewGenerationForFile(at url: URL) -> Bool {
        !generators.filter {
            $0.supportsPreviewGenerationForFile(at: url)
        }.isEmpty
    }

    func generatePreviewForFile(at url: URL) async throws -> UIImage {

        let firstGenerator = generators.first(where: { $0.supportsPreviewGenerationForFile(at: url) })
        if let firstGenerator {
            return try await firstGenerator.generatePreviewForFile(at: url)
        }

        throw AggregateFilePreviewGeneratorError.noMatchingFilePreviewGeneratorFound
    }

    // MARK: -

    enum AggregateFilePreviewGeneratorError: Error {
        /// The `AggregateFilePreviewGenerator` does not contain any generator
        /// which supports generating preview for the provided file type.
        case noMatchingFilePreviewGeneratorFound
    }
}
