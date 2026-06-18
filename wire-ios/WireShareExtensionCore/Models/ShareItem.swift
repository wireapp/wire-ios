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

public enum ShareItem {
    case image(ImageShareItem)
    case video(VideoShareItem)
    case file(FileShareItem)
}

public struct ImageShareItem {

    public let url: URL
    public let name: String
    public let size: Int?

    public static func from(_ provider: NSItemProvider) async throws -> ImageShareItem? {
        guard provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) else {
            return nil
        }

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
            throw error
        }

        return ImageShareItem(
            url: url,
            name: url.lastPathComponent,
            size: try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int
        )
    }

}

public struct VideoShareItem {

    public let url: URL
    public let name: String
    public let size: Int?

    public static func from(_ provider: NSItemProvider) async throws -> VideoShareItem? {
        guard provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) else {
            return nil
        }

        let url: URL
        do {
            let result = try await provider.loadItem(
                forTypeIdentifier: UTType.movie.identifier,
                options: nil
            )

            if let urlResult = result as? URL {
                url = urlResult
            } else {
                print("no url found, skipping")
                return nil
            }
        } catch {
            print("failed to load video: \(error)")
            throw error
        }

        return VideoShareItem(
            url: url,
            name: url.lastPathComponent,
            size: try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int
        )
    }

}

public struct FileShareItem {

    public let url: URL
    public let name: String
    public let mimeType: String
    public let size: Int?

    public static func from(_ provider: NSItemProvider) async throws -> FileShareItem? {
        guard provider.hasItemConformingToTypeIdentifier(UTType.data.identifier) else {
            return nil
        }

        let url: URL
        do {
            let result = try await provider.loadItem(
                forTypeIdentifier: UTType.data.identifier,
                options: nil
            )

            if let urlResult = result as? URL {
                url = urlResult
            } else {
                print("no url found, skipping")
                return nil
            }
        } catch {
            print("failed to load data: \(error)")
            throw error
        }

        return FileShareItem(
            url: url,
            name: url.lastPathComponent,
            mimeType: "application/octet-stream",
            size: try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int
        )
    }

}
