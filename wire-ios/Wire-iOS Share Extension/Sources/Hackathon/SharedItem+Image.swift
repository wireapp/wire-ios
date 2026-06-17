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

import Foundation
import UniformTypeIdentifiers

extension SharedItem {

    static func image(from provider: NSItemProvider) async -> SharedItem? {
        let url: URL
        do {
            let result = try await provider.loadItem(
                forTypeIdentifier: UTType.image.identifier,
                options: nil
            )

            if let urlResult = result as? URL {
                url = urlResult
            } else {
                print("no url found, skipping")
                return nil
            }
        } catch {
            print("failed to load image: \(error)")
            return nil
        }

        return SharedItem(
            type: .image,
            url: url,
            name: url.lastPathComponent,
            mimeType: "image/jpeg",
            size: try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int
        )
    }

}

