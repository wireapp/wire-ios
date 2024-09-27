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

import Foundation
import MobileCoreServices
import WireSystem
import WireUtilities

private let zmLog = ZMSLog(tag: "ZMFileMetadata")

// MARK: - ZMFileMetadata

@objcMembers
open class ZMFileMetadata: NSObject {
    // MARK: Lifecycle

    public required init(fileURL: URL, thumbnail: Data? = nil, name: String? = nil) {
        self.fileURL = fileURL
        self.thumbnail =
            if let thumbnail, !thumbnail.isEmpty {
                thumbnail
            } else {
                nil
            }
        let endName = name ?? (fileURL.lastPathComponent.isEmpty ? "unnamed" : fileURL.lastPathComponent)

        self.filename = endName.removingExtremeCombiningCharacters
        super.init()
    }

    public convenience init(fileURL: URL, thumbnail: Data? = nil) {
        self.init(fileURL: fileURL, thumbnail: thumbnail, name: nil)
    }

    // MARK: Public

    public let fileURL: URL
    public let thumbnail: Data?
    public let filename: String

    // MARK: Internal

    var asset: WireProtos.Asset {
        WireProtos.Asset(self)
    }
}

// MARK: - ZMAudioMetadata

open class ZMAudioMetadata: ZMFileMetadata {
    // MARK: Lifecycle

    public required init(
        fileURL: URL,
        duration: TimeInterval,
        normalizedLoudness: [Float] = [],
        thumbnail: Data? = nil
    ) {
        self.duration = duration
        self.normalizedLoudness = normalizedLoudness

        super.init(fileURL: fileURL, thumbnail: thumbnail, name: nil)
    }

    public required init(fileURL: URL, thumbnail: Data?, name: String? = nil) {
        self.duration = 0
        self.normalizedLoudness = []
        super.init(fileURL: fileURL, thumbnail: thumbnail, name: name)
    }

    // MARK: Public

    public let duration: TimeInterval
    public let normalizedLoudness: [Float]

    // MARK: Internal

    override var asset: WireProtos.Asset {
        WireProtos.Asset(self)
    }
}

// MARK: - ZMVideoMetadata

open class ZMVideoMetadata: ZMFileMetadata {
    // MARK: Lifecycle

    public required init(fileURL: URL, duration: TimeInterval, dimensions: CGSize, thumbnail: Data? = nil) {
        self.duration = duration
        self.dimensions = dimensions

        super.init(fileURL: fileURL, thumbnail: thumbnail, name: nil)
    }

    public required init(fileURL: URL, thumbnail: Data?, name: String? = nil) {
        self.duration = 0
        self.dimensions = CGSize.zero

        super.init(fileURL: fileURL, thumbnail: thumbnail, name: name)
    }

    // MARK: Public

    public let duration: TimeInterval
    public let dimensions: CGSize

    // MARK: Internal

    override var asset: WireProtos.Asset {
        WireProtos.Asset(self)
    }
}

extension ZMFileMetadata {
    public var mimeType: String {
        UTIHelper.convertToMime(fileExtension: fileURL.pathExtension) ?? "application/octet-stream"
    }

    public var size: UInt64 {
        do {
            let attributes = try fileURL.resourceValues(forKeys: [.fileSizeKey])
            let size = attributes.fileSize ?? 0
            return UInt64(size)
        } catch {
            zmLog.error("Couldn't read file size of \(fileURL)")
            return 0
        }
    }
}
