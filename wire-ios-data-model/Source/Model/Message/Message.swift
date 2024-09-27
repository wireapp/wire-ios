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

extension ZMConversationMessage {
    /// Returns YES, if the message has text to display.
    /// This also includes linkPreviews or links to soundcloud, youtube or vimeo
    public var isText: Bool {
        textMessageData != nil
    }

    public var isImage: Bool {
        imageMessageData != nil || (fileMessageData != nil && fileMessageData!.v3_isImage)
    }

    public var isKnock: Bool {
        knockMessageData != nil
    }

    /// Returns YES, if the message is a file transfer message
    /// This also includes audio messages and video messages
    public var isFile: Bool {
        fileMessageData != nil && !fileMessageData!.v3_isImage
    }

    public var isPDF: Bool {
        isFile && fileMessageData?.isPDF ?? false
    }

    public var isPass: Bool {
        isFile && fileMessageData!.isPass
    }

    public var isVideo: Bool {
        isFile && fileMessageData!.isVideo
    }

    public var isAudio: Bool {
        isFile && fileMessageData!.isAudio
    }

    public var isLocation: Bool {
        locationMessageData != nil
    }

    public var isSystem: Bool {
        systemMessageData != nil
    }

    public var isNormal: Bool {
        isText
            || isImage
            || isKnock
            || isFile
            || isVideo
            || isAudio
            || isLocation
    }

    public var isConnectionRequest: Bool {
        guard isSystem else {
            return false
        }
        return systemMessageData!.systemMessageType == .connectionRequest
    }

    public var isMissedCall: Bool {
        guard isSystem else {
            return false
        }
        return systemMessageData!.systemMessageType == .missedCall
    }

    public var isDeletion: Bool {
        guard isSystem else {
            return false
        }
        return systemMessageData!.systemMessageType == .messageDeletedForEveryone
    }
}

extension ConversationCompositeMessage {
    public var isComposite: Bool {
        compositeMessageData != nil
    }
}

// MARK: - Message

/// The `ZMConversationMessage` protocol can not be extended in Objective-C,
/// thus this helper class provides access to commonly used properties.
public class Message: NSObject {
    /// Returns YES, if the message has text to display.
    /// This also includes linkPreviews or links to soundcloud, youtube or vimeo
    @objc(isTextMessage:)
    public class func isText(_ message: ZMConversationMessage) -> Bool {
        message.isText
    }

    @objc(isImageMessage:)
    public class func isImage(_ message: ZMConversationMessage) -> Bool {
        message.isImage
    }

    @objc(isKnockMessage:)
    public class func isKnock(_ message: ZMConversationMessage) -> Bool {
        message.isKnock
    }

    /// Returns YES, if the message is a file transfer message
    /// This also includes audio messages and video messages
    @objc(isFileTransferMessage:)
    public class func isFileTransfer(_ message: ZMConversationMessage) -> Bool {
        message.isFile
    }

    @objc(isPDFMessage:)
    public class func isPDF(_ message: ZMConversationMessage) -> Bool {
        message.isPDF
    }

    @objc(isVideoMessage:)
    public class func isVideo(_ message: ZMConversationMessage) -> Bool {
        message.isVideo
    }

    @objc(isAudioMessage:)
    public class func isAudio(_ message: ZMConversationMessage) -> Bool {
        message.isAudio
    }

    @objc(isLocationMessage:)
    public class func isLocation(_ message: ZMConversationMessage) -> Bool {
        message.isLocation
    }

    @objc(isSystemMessage:)
    public class func isSystem(_ message: ZMConversationMessage) -> Bool {
        message.isSystem
    }

    @objc(isNormalMessage:)
    public class func isNormal(_ message: ZMConversationMessage) -> Bool {
        message.isNormal
    }

    @objc(isConnectionRequestMessage:)
    public class func isConnectionRequest(_ message: ZMConversationMessage) -> Bool {
        message.isConnectionRequest
    }

    @objc(isMissedCallMessage:)
    public class func isMissedCall(_ message: ZMConversationMessage) -> Bool {
        message.isMissedCall
    }

    @objc(isDeletedMessage:)
    public class func isDeleted(_ message: ZMConversationMessage) -> Bool {
        message.isDeletion
    }
}
