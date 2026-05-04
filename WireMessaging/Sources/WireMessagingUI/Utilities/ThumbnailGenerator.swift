//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

@preconcurrency import QuickLookThumbnailing
import UIKit

/// An object that generates thumbnail images based on provided requirements.

protocol ThumbnailGenerator: Sendable {

    /// Generates a thumbnail image for the file at the specified URL with the given size and scale.

    func generateThumbnail(fileAt url: URL, size: CGSize, scale: Double) async throws -> UIImage

}

extension QLThumbnailGenerator: ThumbnailGenerator, @unchecked @retroactive Sendable {

    func generateThumbnail(fileAt url: URL, size: CGSize, scale: Double) async throws -> UIImage {
        let request = QLThumbnailGenerator.Request(
            fileAt: url,
            size: size,
            scale: scale,
            representationTypes: .thumbnail
        )

        return try await generateBestRepresentation(for: request).uiImage
    }

}
