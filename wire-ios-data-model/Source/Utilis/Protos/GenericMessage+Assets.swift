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

extension WireProtos.Asset {
    public init(_ metadata: ZMFileMetadata) {
        self = WireProtos.Asset.with {
            $0.original = WireProtos.Asset.Original.with {
                $0.size = metadata.size
                $0.mimeType = metadata.mimeType
                $0.name = metadata.filename
            }
        }
    }

    public init(_ metadata: ZMAudioMetadata) {
        self = WireProtos.Asset.with {
            $0.original = WireProtos.Asset.Original.with {
                $0.size = metadata.size
                $0.mimeType = metadata.mimeType
                $0.name = metadata.filename
                $0.audio = WireProtos.Asset.AudioMetaData.with {
                    let loudnessArray = metadata.normalizedLoudness.map { UInt8(roundf($0 * 255)) }
                    $0.durationInMillis = UInt64(metadata.duration * 1000)
                    $0.normalizedLoudness = NSData(bytes: loudnessArray, length: loudnessArray.count) as Data
                }
            }
        }
    }

    public init(_ metadata: ZMVideoMetadata) {
        self = WireProtos.Asset.with {
            $0.original = WireProtos.Asset.Original.with {
                $0.size = metadata.size
                $0.mimeType = metadata.mimeType
                $0.name = metadata.filename
                $0.video = WireProtos.Asset.VideoMetaData.with {
                    $0.durationInMillis = UInt64(metadata.duration * 1000)
                    $0.width = Int32(metadata.dimensions.width)
                    $0.height = Int32(metadata.dimensions.height)
                }
            }
        }
    }

    public init(imageSize: CGSize, mimeType: String, size: UInt64) {
        self = WireProtos.Asset.with {
            $0.original = WireProtos.Asset.Original.with {
                $0.size = size
                $0.mimeType = mimeType
                $0.image = WireProtos.Asset.ImageMetaData.with {
                    $0.width = Int32(imageSize.width)
                    $0.height = Int32(imageSize.height)
                }
            }
        }
    }

    public init(original: WireProtos.Asset.Original?, preview: WireProtos.Asset.Preview?) {
        self = WireProtos.Asset.with {
            if let original {
                $0.original = original
            }
            if let preview {
                $0.preview = preview
            }
        }
    }

    public init(withUploadedOTRKey otrKey: Data, sha256: Data) {
        self = WireProtos.Asset.with {
            $0.uploaded = WireProtos.Asset.RemoteData(withOTRKey: otrKey, sha256: sha256)
        }
    }

    public init(withNotUploaded notUploaded: WireProtos.Asset.NotUploaded) {
        self = WireProtos.Asset.with {
            $0.notUploaded = notUploaded
        }
    }

    public var hasUploaded: Bool {
        guard case .uploaded? = status else {
            return false
        }
        return true
    }

    public var hasNotUploaded: Bool {
        guard case .notUploaded? = status else {
            return false
        }
        return true
    }
}

extension WireProtos.Asset.Original {
    public init(
        withSize size: UInt64,
        mimeType: String,
        name: String?,
        imageMetaData: WireProtos.Asset.ImageMetaData? = nil
    ) {
        self = WireProtos.Asset.Original.with {
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

    public init(
        withSize size: UInt64,
        mimeType: String,
        name: String?,
        audioDurationInMillis: UInt,
        normalizedLoudness: [Float]
    ) {
        self = WireProtos.Asset.Original.with {
            $0.size = size
            $0.mimeType = mimeType
            if let name {
                $0.name = name
            }
            $0.audio = WireProtos.Asset.AudioMetaData.with {
                $0.durationInMillis = UInt64(audioDurationInMillis)
                let loudnessArray = normalizedLoudness.map { UInt8(roundf($0 * 255)) }
                $0.normalizedLoudness = Data(bytes: loudnessArray, count: loudnessArray.count)
            }
        }
    }

    /// Returns the normalized loudness as floats between 0 and 1
    public var normalizedLoudnessLevels: [Float] {
        guard audio.hasNormalizedLoudness else {
            return []
        }
        guard !audio.normalizedLoudness.isEmpty else {
            return []
        }

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

extension WireProtos.Asset.Preview {
    public init(
        size: UInt64,
        mimeType: String,
        remoteData: WireProtos.Asset.RemoteData?,
        imageMetadata: WireProtos.Asset.ImageMetaData
    ) {
        self = WireProtos.Asset.Preview.with {
            $0.size = size
            $0.mimeType = mimeType
            $0.image = imageMetadata
            if let remoteData {
                $0.remote = remoteData
            }
        }
    }
}

extension WireProtos.Asset.ImageMetaData {
    public init(width: Int32, height: Int32) {
        self = WireProtos.Asset.ImageMetaData.with {
            $0.width = width
            $0.height = height
        }
    }
}

extension WireProtos.Asset.RemoteData {
    public init(
        withOTRKey otrKey: Data,
        sha256: Data,
        assetId: String? = nil,
        assetToken: String? = nil,
        assetDomain: String? = nil
    ) {
        self = WireProtos.Asset.RemoteData.with {
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
        let asset = WireProtos.Asset(
            imageSize: imageProperties.size,
            mimeType: imageProperties.mimeType,
            size: UInt64(imageProperties.length)
        )
        update(asset: asset)
    }

    mutating func updateAssetPreview(withUploadedOTRKey otrKey: Data, sha256: Data) {
        guard var preview = assetData?.preview else {
            return
        }

        preview.remote = WireProtos.Asset.RemoteData(withOTRKey: otrKey, sha256: sha256)
        let asset = WireProtos.Asset(original: nil, preview: preview)

        update(asset: asset)
    }

    mutating func updateAssetPreview(withImageProperties imageProperties: ZMIImageProperties) {
        let imageMetaData = WireProtos.Asset.ImageMetaData(
            width: Int32(imageProperties.size.width),
            height: Int32(imageProperties.size.height)
        )
        let preview = WireProtos.Asset.Preview(
            size: UInt64(imageProperties.length),
            mimeType: imageProperties.mimeType,
            remoteData: nil,
            imageMetadata: imageMetaData
        )
        let asset = WireProtos.Asset(original: nil, preview: preview)
        update(asset: asset)
    }

    mutating func updateAsset(withUploadedOTRKey otrKey: Data, sha256: Data) {
        let asset = WireProtos.Asset(withUploadedOTRKey: otrKey, sha256: sha256)
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

    public mutating func update(asset: WireProtos.Asset) {
        updateAsset { $0 = asset }
    }

    mutating func updateAsset(_ block: (inout WireProtos.Asset) -> Void) {
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

extension WireProtos.Asset.RemoteData {
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
