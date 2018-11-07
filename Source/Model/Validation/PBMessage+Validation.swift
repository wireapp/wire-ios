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

extension UUID {

    public static func isValid(object: Any?) -> Bool {
        guard let string = object as? String else { return false }
        return UUID(uuidString: string) != nil
    }

    public static func isValid(bytes: Data?) -> Bool {
        return bytes?.count == 16
    }

    public static func isValid(array: [Any]?) -> Bool {
        return array?.map(UUID.isValid).contains(false) == false
    }

}

// MARK: - String Formatting

extension String {

    public var isValidAssetID: Bool {

        // Format: https://github.com/wireapp/wire-webapp/blob/dev/app/script/util/ValidationUtil.js

        var assetIDAllowedCharacters = CharacterSet()
        assetIDAllowedCharacters.formUnion(.decimalDigits) // numbers
        assetIDAllowedCharacters.insert(charactersIn: "A" ... "Z") // A-Z
        assetIDAllowedCharacters.insert(charactersIn: "a" ... "z") // a-z
        assetIDAllowedCharacters.insert("-") // hyphen

        return self.trimmingCharacters(in: assetIDAllowedCharacters).isEmpty

    }

    public var isValidBearerToken: Bool {

        // Format: https://github.com/wireapp/wire-webapp/blob/dev/app/script/util/ValidationUtil.js

        let decodedAssetToken = self.removingPercentEncoding ?? self

        var assetTokenAllowedCharacters = CharacterSet()
        assetTokenAllowedCharacters.formUnion(.decimalDigits) // numbers
        assetTokenAllowedCharacters.insert(charactersIn: "A" ... "Z") // A-Z
        assetTokenAllowedCharacters.insert(charactersIn: "a" ... "z") // a-z
        assetTokenAllowedCharacters.insert(charactersIn: "-._~+/") // special characters

        // Check the last non-alphanumerical characters (can be 0-2 equal signs)

        let disallowedSuffix = decodedAssetToken.unicodeScalars.drop(while: assetTokenAllowedCharacters.contains)

        switch String(disallowedSuffix) {
        case "", "=", "==":
            return true

        default:
            return false
        }

    }

}

// MARK: - Specific Validation

// MARK: Generic Message

extension ZMGenericMessage {
    @objc public func validatingFields() -> ZMGenericMessage? {
        // Validate the message itself
        guard UUID.isValid(object: messageId) else { return nil }

        // Validate the mentions in the text
        if self.hasText() {
            guard self.text!.validatingFields() != nil else { return nil }
        }

        // Validate the last read
        if self.hasLastRead() {
            guard self.lastRead!.validatingFields() != nil else { return nil }
        }

        // Validate the cleared
        if self.hasCleared() {
            guard self.cleared!.validatingFields() != nil else { return nil }
        }

        // Validate the hide
        if self.hasHidden() {
            guard self.hidden!.validatingFields() != nil else { return nil }
        }

        // Validate the delete
        if self.hasDeleted() {
            guard self.deleted!.validatingFields() != nil else { return nil }
        }

        // Validate the edit
        if self.hasEdited() {
            guard self.edited!.validatingFields() != nil else { return nil }
        }

        // Validate the confirmation
        if self.hasConfirmation() {
            guard self.confirmation!.validatingFields() != nil else { return nil }
        }

        // Validate the reaction
        if self.hasReaction() {
            guard self.reaction!.validatingFields() != nil else { return nil }
        }

        // Validate the asset
        if self.hasAsset() {
            guard self.asset!.validatingFields() != nil else { return nil }
        }

        return self
    }
}

extension ZMGenericMessageBuilder {
    @objc public func buildAndValidate() -> ZMGenericMessage? {
        return self.build()?.validatingFields()
    }
}

// MARK: - Text

extension ZMText {
    @objc public func validatingFields() -> ZMText? {

        if let mentions = self.mentions {
            let validMentions = mentions.compactMap { $0.validatingFields() }
            guard validMentions.count == mentions.count else { return nil }
        }

        return self

    }
}

// MARK: Quotes

extension ZMQuote {
    @objc public func validatingFields() -> ZMQuote? {
        guard UUID.isValid(object: quotedMessageId) else { return nil }
        return self
    }
}

// MARK: Mention

extension ZMMention {
    @objc public func validatingFields() -> ZMMention? {
        guard UUID.isValid(object: userId) else { return nil }
        return self
    }
}

// MARK: Last Read

extension ZMLastRead {
    @objc public func validatingFields() -> ZMLastRead? {
        guard UUID.isValid(object: conversationId) else { return nil }
        return self
    }
}

// MARK: Cleared

extension ZMCleared {
    @objc public func validatingFields() -> ZMCleared? {
        guard UUID.isValid(object: conversationId) else { return nil }
        return self
    }
}

// MARK: Message Hide

extension ZMMessageHide {
    @objc public func validatingFields() -> ZMMessageHide? {
        guard UUID.isValid(object: conversationId) else { return nil }
        guard UUID.isValid(object: messageId) else { return nil }
        return self
    }
}

// MARK: Message Delete

extension ZMMessageDelete {
    @objc public func validatingFields() -> ZMMessageDelete? {
        guard UUID.isValid(object: messageId) else { return nil }
        return self
    }
}

// MARK: Message Edit

extension ZMMessageEdit {
    @objc public func validatingFields() -> ZMMessageEdit? {
        guard UUID.isValid(object: replacingMessageId) else { return nil }
        return self
    }
}

// MARK: Message Confirmation

extension ZMConfirmation {
    @objc public func validatingFields() -> ZMConfirmation? {
        guard UUID.isValid(object: firstMessageId) else { return nil }

        if self.moreMessageIds != nil {
            guard UUID.isValid(array: moreMessageIds) else { return nil }
        }

        return self
    }
}

// MARK: Reaction

extension ZMReaction {
    @objc public func validatingFields() -> ZMReaction? {
        guard UUID.isValid(object: messageId) else { return nil }
        return self
    }
}

// MARK: User ID

extension ZMUserId {
    @objc public func validatingFields() -> ZMUserId? {
        guard UUID.isValid(bytes: uuid) else { return nil }
        return self
    }
}

// MARK: - Asset

extension ZMAsset {

    @objc public func validatingFields() -> ZMAsset? {

        if self.hasPreview() && self.preview!.hasRemote() {
            guard self.preview.remote.validatingFields() != nil else { return nil }
        }

        if self.hasUploaded() {
            guard self.uploaded.validatingFields() != nil else { return nil }
        }

        return self

    }

}

extension ZMAssetRemoteData {

    @objc public func validatingFields() -> ZMAssetRemoteData? {

        // Validate the asset ID

        if let assetID = assetId, assetID.isEmpty == false {

            guard assetID.isValidAssetID else {
                return nil
            }

        }

        // Check if the token is in the bearer token format

        if let assetToken = assetToken, assetToken.isEmpty == false {

            guard assetToken.isValidBearerToken else {
                return nil
            }

        }

        return self

    }

}
