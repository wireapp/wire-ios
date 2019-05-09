//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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


@objc public extension ZMAsset {
    
    static func asset(withOriginal original: ZMAssetOriginal? = nil, preview: ZMAssetPreview? = nil) -> ZMAsset {
        let builder = ZMAsset.builder()!
        if let original = original {
            builder.setOriginal(original)
        }
        if let preview = preview {
            builder.setPreview(preview)
        }
        return builder.build()
    }
    
    static func asset(withUploadedOTRKey otrKey: Data, sha256: Data) -> ZMAsset {
        let builder = ZMAsset.builder()!
        builder.setUploaded(.remoteData(withOTRKey: otrKey, sha256: sha256))
        return builder.build()
    }
    
    static func asset(withNotUploaded notUploaded: ZMAssetNotUploaded) -> ZMAsset {
        let builder = ZMAsset.builder()!
        builder.setNotUploaded(notUploaded)
        return builder.build()
    }
    
}

@objc public extension ZMAssetOriginal {
    
    static func original(withSize size: UInt64, mimeType: String, name: String?) -> ZMAssetOriginal {
        return original(withSize: size, mimeType: mimeType, name: name, imageMetaData: nil)
    }
    
    static func original(withSize size: UInt64, mimeType: String, name: String?, imageMetaData: ZMAssetImageMetaData?) -> ZMAssetOriginal {
        let builder = ZMAssetOriginal.builder()!
        builder.setSize(size)
        builder.setMimeType(mimeType)
        if let name = name {
            builder.setName(name)
        }
        if let imageMeta = imageMetaData {
            builder.setImage(imageMeta)
        }
        return builder.build()
    }
    
    static func original(withSize size: UInt64, mimeType: String, name: String, videoDurationInMillis: UInt, videoDimensions: CGSize) -> ZMAssetOriginal {
        let builder = ZMAssetOriginal.builder()!
        builder.setSize(size)
        builder.setMimeType(mimeType)
        builder.setName(name)
        
        let videoBuilder = ZMAssetVideoMetaData.builder()!
        videoBuilder.setDurationInMillis(UInt64(videoDurationInMillis))
        videoBuilder.setWidth(Int32(videoDimensions.width))
        videoBuilder.setHeight(Int32(videoDimensions.height))
        builder.setVideo(videoBuilder)
        
        return builder.build()
    }
    
    static func original(withSize size: UInt64, mimeType: String, name: String, audioDurationInMillis: UInt, normalizedLoudness: [Float]) -> ZMAssetOriginal {
        let builder = ZMAssetOriginal.builder()!
        builder.setSize(size)
        builder.setMimeType(mimeType)
        builder.setName(name)
        
        let loudnessArray = normalizedLoudness.map { UInt8(roundf($0*255)) }
        let audioBuilder = ZMAssetAudioMetaData.builder()!
        audioBuilder.setDurationInMillis(UInt64(audioDurationInMillis))
        audioBuilder.setNormalizedLoudness(NSData(bytes: loudnessArray, length: loudnessArray.count) as Data)
        builder.setAudio(audioBuilder)
        
        return builder.build()
    }
    
    /// Returns the normalized loudness as floats between 0 and 1
    var normalizedLoudnessLevels : [Float] {
        
        guard self.audio.hasNormalizedLoudness() else { return [] }
        guard self.audio.normalizedLoudness.count > 0 else { return [] }
        
        guard let data = self.audio.normalizedLoudness else {return []}
        let offsets = 0..<data.count
        return offsets.map { offset -> UInt8 in
            var number : UInt8 = 0
            data.copyBytes(to: &number, from: (0 + offset)..<(MemoryLayout<UInt8>.size+offset))
            return number
            }
            .map { Float(Float($0)/255.0) }
    }
}

@objc public extension ZMAssetPreview {
    
    static func preview(withSize size: UInt64, mimeType: String, remoteData: ZMAssetRemoteData?, imageMetadata: ZMAssetImageMetaData) -> ZMAssetPreview {
        let builder = ZMAssetPreview.builder()!
        builder.setSize(size)
        builder.setMimeType(mimeType)
        builder.setImage(imageMetadata)
        
        if let remoteData = remoteData {
            builder.setRemote(remoteData)
        }
        
        return builder.build()
    }
    
}

@objc public extension ZMAssetImageMetaData {
    static func imageMetaData(withWidth width: Int32, height: Int32) -> ZMAssetImageMetaData {
        let builder = ZMAssetImageMetaData.builder()!
        builder.setWidth(width)
        builder.setHeight(height)
        return builder.build()
    }
}

@objc public extension ZMAssetRemoteData {
    
    static func remoteData(withOTRKey otrKey: Data, sha256: Data, assetId: String? = nil, assetToken: String? = nil) -> ZMAssetRemoteData {
        let builder = ZMAssetRemoteData.builder()!
        builder.setOtrKey(otrKey)
        builder.setSha256(sha256)
        if let identifier = assetId {
            builder.setAssetId(identifier)
        }
        if let token = assetToken {
            builder.setAssetToken(token)
        }
        return builder.build()
    }
}


@objc extension ZMAssetRemoteData {
    func builder(withAssetID assetID: String, token: String?) -> ZMAssetRemoteDataBuilder {
        let builder = toBuilder()!
        builder.setAssetId(assetID)
        if let token = token {
            builder.setAssetToken(token)
        }
        return builder
    }
}

// MARK: - Equatable

func ==(lhs: ZMAssetPreview, rhs: ZMAssetPreview) -> Bool {
    return lhs.data() == rhs.data()
}
