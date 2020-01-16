//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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
import WireProtos

public protocol MessageCapable {
    func setContent(on message: inout GenericMessage)
    var expectsReadConfirmation: Bool { get set }
}

public protocol EphemeralMessageCapable: MessageCapable {
    func setEphemeralContent(on ephemeral: inout Ephemeral)
}

public extension GenericMessage {
    static func message(content: EphemeralMessageCapable, nonce: UUID = UUID(), expiresAfter timeout: TimeInterval? = nil) -> GenericMessage {
        return GenericMessage.with() {
            $0.messageID = nonce.transportString()
            let messageContent: MessageCapable
            if let timeout = timeout, timeout > 0 {
                messageContent = Ephemeral.ephemeral(content: content, expiresAfter: timeout)
            } else {
                messageContent = content
            }
            messageContent.setContent(on: &$0)
        }
    }
}

extension GenericMessage {
    var locationData: Location? {
        guard let content = content else { return nil }
        switch content {
        case .location(let data):
            return data
        case .ephemeral(let data):
            switch data.content {
            case .location(let data)?:
                return data
            default:
                return nil
            }
        default:
            return nil
        }        
    }
    
    var imageAssetData : ImageAsset? {
        guard let content = content else { return nil }
        switch content {
        case .image(let data):
            return data
        case .ephemeral(let data):
            switch data.content {
            case .image(let data)?:
                return data
            default:
                return nil
            }
        default:
            return nil
        }        
    }

}

extension Ephemeral: MessageCapable {
    public var expectsReadConfirmation: Bool {
        get {
            guard let content = content else { return false }
            switch content {
            case let .text(value):
                return value.expectsReadConfirmation
            case .image:
                return false
            case let .knock(value):
                return value.expectsReadConfirmation
            case let .asset(value):
                return value.expectsReadConfirmation
            case let .location(value):
                return value.expectsReadConfirmation
            }
        }
        set {
            guard let content = content else { return }
            switch content {
            case .text:
                text.expectsReadConfirmation = newValue
            case .image:
                break
            case .knock:
                knock.expectsReadConfirmation = newValue
            case .asset:
                knock.expectsReadConfirmation = newValue
            case .location:
                location.expectsReadConfirmation = newValue
            }
        }
    }
    
    public static func ephemeral(content: EphemeralMessageCapable, expiresAfter timeout: TimeInterval) -> Ephemeral {
        return Ephemeral.with() { 
            $0.expireAfterMillis = Int64(timeout * 1000)
            content.setEphemeralContent(on: &$0)
        }
    }
    
    public func setContent(on message: inout GenericMessage) {
        message.ephemeral = self
    }
}

extension Location: EphemeralMessageCapable {
    public func setEphemeralContent(on ephemeral: inout Ephemeral) {
        ephemeral.location = self
    }
    
    public func setContent(on message: inout GenericMessage) {
        message.location = self
    }
}

extension Knock: EphemeralMessageCapable {
    public func setEphemeralContent(on ephemeral: inout Ephemeral) {
        ephemeral.knock = self
    }
    
    public func setContent(on message: inout GenericMessage) {
        message.knock = self
    }
}

extension Text: EphemeralMessageCapable {
    
    init(content: String, mentions: [Mention], replyingTo: ZMOTRMessage?) {
        self = Text.with {
            $0.content = content
            $0.mentions = mentions.compactMap { WireProtos.Mention($0) }
            
            if let quotedMessage = replyingTo,
               let quotedMessageNonce = quotedMessage.nonce,
               let quotedMessageHash = quotedMessage.hashOfContent {
                $0.quote = Quote.with({
                    $0.quotedMessageID = quotedMessageNonce.transportString()
                    $0.quotedMessageSha256 = quotedMessageHash
                })
            }
        }
    }
    
    public func setEphemeralContent(on ephemeral: inout Ephemeral) {
        ephemeral.text = self
    }
    
    public func setContent(on message: inout GenericMessage) {
        message.text = self
    }
}

extension WireProtos.Asset: EphemeralMessageCapable {
    
    init(_ metadata: ZMFileMetadata) {
        self = WireProtos.Asset.with({
            $0.original = WireProtos.Asset.Original.with({
                $0.size = metadata.size
                $0.mimeType = metadata.mimeType
                $0.name = metadata.filename
            })
        })
    }
    
    init(_ metadata: ZMAudioMetadata) {
        self = WireProtos.Asset.with({
            $0.original = WireProtos.Asset.Original.with({
                $0.size = metadata.size
                $0.mimeType = metadata.mimeType
                $0.name = metadata.filename
                $0.audio = WireProtos.Asset.AudioMetaData.with({
                    let loudnessArray = metadata.normalizedLoudness.map { UInt8(roundf($0 * 255)) }
                    $0.durationInMillis = UInt64(metadata.duration * 1000)
                    $0.normalizedLoudness = NSData(bytes: loudnessArray, length: loudnessArray.count) as Data
                })
                
            })
        })
    }
    
    init(_ metadata: ZMVideoMetadata) {
        self = WireProtos.Asset.with({
            $0.original = WireProtos.Asset.Original.with({
                $0.size = metadata.size
                $0.mimeType = metadata.mimeType
                $0.name = metadata.filename
                $0.video = WireProtos.Asset.VideoMetaData.with({
                    $0.durationInMillis = UInt64(metadata.duration * 1000)
                    $0.width = Int32(metadata.dimensions.width)
                    $0.height = Int32(metadata.dimensions.height)
                })
            })
        })
    }
    
    init(imageSize: CGSize, mimeType: String, size: UInt64) {
        self = WireProtos.Asset.with({
            $0.original = WireProtos.Asset.Original.with({
                $0.size = size
                $0.mimeType = mimeType
                $0.image = WireProtos.Asset.ImageMetaData.with({
                    $0.width = Int32(imageSize.width)
                    $0.height = Int32(imageSize.height)
                })
            })
        })
    }
    
    public func setEphemeralContent(on ephemeral: inout Ephemeral) {
        ephemeral.asset = self
    }
    
    public func setContent(on message: inout GenericMessage) {
        message.asset = self
    }
}

extension WireProtos.Mention {
    
    init?(_ mention: WireDataModel.Mention) {
        guard let userID = (mention.user as? ZMUser)?.remoteIdentifier.transportString() else { return nil }
        
        self = WireProtos.Mention.with {
            $0.start = Int32(mention.range.location)
            $0.length = Int32(mention.range.length)
            $0.userID = userID
        }
    }
    
}
