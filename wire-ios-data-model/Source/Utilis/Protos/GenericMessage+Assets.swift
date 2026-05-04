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
import GenericMessageProtocol

public extension GenericMessageProtocol.Asset {
    init(_ metadata: ZMFileMetadata) {
        self = GenericMessageProtocol.Asset.with {
            $0.original = GenericMessageProtocol.Asset.Original.with {
                $0.size = metadata.size
                $0.mimeType = metadata.mimeType
                $0.name = metadata.filename
            }
        }
    }

    init(_ metadata: ZMAudioMetadata) {
        self = GenericMessageProtocol.Asset.with {
            $0.original = GenericMessageProtocol.Asset.Original.with {
                $0.size = metadata.size
                $0.mimeType = metadata.mimeType
                $0.name = metadata.filename
                $0.audio = GenericMessageProtocol.Asset.AudioMetaData.with {
                    let loudnessArray = metadata.normalizedLoudness.map { UInt8(roundf($0 * 255)) }
                    $0.durationInMillis = UInt64(metadata.duration * 1000)
                    $0.normalizedLoudness = NSData(bytes: loudnessArray, length: loudnessArray.count) as Data
                }
            }
        }
    }

    init(_ metadata: ZMVideoMetadata) {
        self = GenericMessageProtocol.Asset.with {
            $0.original = GenericMessageProtocol.Asset.Original.with {
                $0.size = metadata.size
                $0.mimeType = metadata.mimeType
                $0.name = metadata.filename
                $0.video = GenericMessageProtocol.Asset.VideoMetaData.with {
                    $0.durationInMillis = UInt64(metadata.duration * 1000)
                    $0.width = Int32(metadata.dimensions.width)
                    $0.height = Int32(metadata.dimensions.height)
                }
            }
        }
    }

    init(
        name: String,
        mimeType: String,
        imageSize: CGSize,
        size: UInt64
    ) {
        self = GenericMessageProtocol.Asset.with {
            $0.original = GenericMessageProtocol.Asset.Original.with {
                $0.name = name
                $0.mimeType = mimeType
                $0.size = size
                $0.image = GenericMessageProtocol.Asset.ImageMetaData.with {
                    $0.width = Int32(imageSize.width)
                    $0.height = Int32(imageSize.height)
                }
            }
        }
    }

    init(original: GenericMessageProtocol.Asset.Original?, preview: GenericMessageProtocol.Asset.Preview?) {
        self = GenericMessageProtocol.Asset.with {
            if let original {
                $0.original = original
            }
            if let preview {
                $0.preview = preview
            }
        }
    }

    init(withUploadedOTRKey otrKey: Data, sha256: Data) {
        self = GenericMessageProtocol.Asset.with {
            $0.uploaded = GenericMessageProtocol.Asset.RemoteData(withOTRKey: otrKey, sha256: sha256)
        }
    }

    init(withNotUploaded notUploaded: GenericMessageProtocol.Asset.NotUploaded) {
        self = GenericMessageProtocol.Asset.with {
            $0.notUploaded = notUploaded
        }
    }

    var hasUploaded: Bool {
        guard case .uploaded? = status else {
            return false
        }
        return true
    }

    var hasNotUploaded: Bool {
        guard case .notUploaded? = status else {
            return false
        }
        return true
    }
}

public extension GenericMessageProtocol.Asset.Original {

    init(
        withSize size: UInt64,
        mimeType: String,
        name: String?,
        imageMetaData: GenericMessageProtocol.Asset.ImageMetaData? = nil
    ) {
        self = GenericMessageProtocol.Asset.Original.with {
            $0.size = size
            $0.mimeType = mimeType
            if let name {
                $0.name = name
            }
            if let imageMeta = imageMetaData {
                $0.image = imageMeta
            }
        }
    }

    init(
        withSize size: UInt64,
        mimeType: String,
        name: String?,
        audioDurationInMillis: UInt,
        normalizedLoudness: [Float]
    ) {
        self = GenericMessageProtocol.Asset.Original.with {
            $0.size = size
            $0.mimeType = mimeType
            if let name {
                $0.name = name
            }
            $0.audio = GenericMessageProtocol.Asset.AudioMetaData.with {
                $0.durationInMillis = UInt64(audioDurationInMillis)
                let loudnessArray = normalizedLoudness.map { UInt8(roundf($0 * 255)) }
                $0.normalizedLoudness = Data(bytes: loudnessArray, count: loudnessArray.count)
            }
        }
    }

    /// Returns the normalized loudness as floats between 0 and 1
    var normalizedLoudnessLevels: [Float] {

        guard audio.hasNormalizedLoudness else { return [] }
        guard !audio.normalizedLoudness.isEmpty else { return [] }

        let data = audio.normalizedLoudness
        let offsets = 0 ..< data.count
        return offsets
            .map { offset -> UInt8 in
                var number: UInt8 = 0
                data.copyBytes(to: &number, from: (0 + offset) ..< (MemoryLayout<UInt8>.size + offset))
                return number
            }
            .map {
                Float(Float($0) / 255.0)
            }
    }
}

public extension GenericMessageProtocol.Asset.Preview {

    init(
        size: UInt64,
        mimeType: String,
        remoteData: GenericMessageProtocol.Asset.RemoteData?,
        imageMetadata: GenericMessageProtocol.Asset.ImageMetaData
    ) {
        self = GenericMessageProtocol.Asset.Preview.with {
            $0.size = size
            $0.mimeType = mimeType
            $0.image = imageMetadata
            if let remoteData {
                $0.remote = remoteData
            }
        }
    }
}

public extension GenericMessageProtocol.Asset.ImageMetaData {
    init(width: Int32, height: Int32) {
        self = GenericMessageProtocol.Asset.ImageMetaData.with {
            $0.width = width
            $0.height = height
        }
    }
}

public extension GenericMessageProtocol.Asset.RemoteData {
    init(
        withOTRKey otrKey: Data,
        sha256: Data,
        assetId: String? = nil,
        assetToken: String? = nil,
        assetDomain: String? = nil
    ) {
        self = GenericMessageProtocol.Asset.RemoteData.with {
            $0.otrKey = otrKey
            $0.sha256 = sha256
            if let id = assetId {
                $0.assetID = id
            }
            if let token = assetToken {
                $0.assetToken = token
            }
            if let domain = assetDomain {
                $0.assetDomain = domain
            }
        }
    }
}

// MARK: - Update assets

extension GenericMessage {
    mutating func updateAssetOriginal(withImageProperties imageProperties: ZMIImageProperties) {
        updateAsset { existingAsset in
            existingAsset.original.mimeType = imageProperties.mimeType
            existingAsset.original.size = UInt64(imageProperties.length)
            existingAsset.original.image = GenericMessageProtocol.Asset.ImageMetaData.with {
                $0.width = Int32(imageProperties.size.width)
                $0.height = Int32(imageProperties.size.height)
            }
        }
    }

    mutating func updateAssetPreview(withUploadedOTRKey otrKey: Data, sha256: Data) {
        guard var preview = assetData?.preview else { return }

        preview.remote = GenericMessageProtocol.Asset.RemoteData(withOTRKey: otrKey, sha256: sha256)
        let asset = GenericMessageProtocol.Asset(original: nil, preview: preview)

        update(asset: asset)
    }

    mutating func updateAssetPreview(withImageProperties imageProperties: ZMIImageProperties) {
        let imageMetaData = GenericMessageProtocol.Asset.ImageMetaData(
            width: Int32(imageProperties.size.width),
            height: Int32(imageProperties.size.height)
        )
        let preview = GenericMessageProtocol.Asset.Preview(
            size: UInt64(imageProperties.length),
            mimeType: imageProperties.mimeType,
            remoteData: nil,
            imageMetadata: imageMetaData
        )
        let asset = GenericMessageProtocol.Asset(original: nil, preview: preview)
        update(asset: asset)
    }

    mutating func updateAsset(withUploadedOTRKey otrKey: Data, sha256: Data) {
        let asset = GenericMessageProtocol.Asset(withUploadedOTRKey: otrKey, sha256: sha256)
        update(asset: asset)
    }

    public mutating func updatePreview(assetId: String, token: String?, domain: String?) {
        updateAsset {
            $0.preview.remote.update(assetId: assetId, token: token, domain: domain)
        }
    }

    public mutating func updateUploaded(assetId: String, token: String?, domain: String?) {
        updateAsset {
            $0.uploaded.update(assetId: assetId, token: token, domain: domain)
        }
    }

    public mutating func update(asset: GenericMessageProtocol.Asset) {
        updateAsset { $0 = asset }
    }

    mutating func updateAsset(_ block: (inout GenericMessageProtocol.Asset) -> Void) {
        guard let content else {
            return
        }
        switch content {
        case .asset:
            block(&asset)
        case .ephemeral:
            guard case .asset = ephemeral.content else {
                return
            }
            block(&ephemeral.asset)
        default:
            return
        }
    }
}

extension GenericMessageProtocol.Asset.RemoteData {
    mutating func update(assetId: String, token: String?, domain: String?) {
        assetID = assetId

        if let token {
            assetToken = token
        }

        if let domain {
            assetDomain = domain
        }
    }
}
