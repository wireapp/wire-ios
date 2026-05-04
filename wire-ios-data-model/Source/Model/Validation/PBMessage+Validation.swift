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

public extension UUID {

    static func isValid(object: Any?) -> Bool {
        guard let string = object as? String else { return false }
        return UUID(uuidString: string) != nil
    }

    static func isValid(bytes: Data?) -> Bool {
        bytes?.count == 16
    }

    static func isValid(array: [Any]?) -> Bool {
        array?.map(UUID.isValid).contains(false) == false
    }

}

// MARK: - String Formatting

public extension String {

    var isValidAssetID: Bool {

        // Format: https://github.com/wireapp/wire-webapp/blob/dev/app/script/util/ValidationUtil.js

        var assetIDAllowedCharacters = CharacterSet()
        assetIDAllowedCharacters.formUnion(.decimalDigits) // numbers
        assetIDAllowedCharacters.insert(charactersIn: "A" ... "Z") // A-Z
        assetIDAllowedCharacters.insert(charactersIn: "a" ... "z") // a-z
        assetIDAllowedCharacters.insert("-") // hyphen

        return trimmingCharacters(in: assetIDAllowedCharacters).isEmpty

    }

    var isValidBearerToken: Bool {

        // Format: https://github.com/wireapp/wire-webapp/blob/dev/app/script/util/ValidationUtil.js

        let decodedAssetToken = removingPercentEncoding ?? self

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

public extension GenericMessage {
    func validateFields() -> Bool {
        guard UUID.isValid(object: messageID), let content else { return false }

        switch content {
        case .text:
            guard text.validatingFields() != nil else { return false }
        case .lastRead:
            guard lastRead.validatingFields() != nil else { return false }
        case .cleared:
            guard cleared.validatingFields() != nil else { return false }
        case .hidden:
            guard hidden.validatingFields() != nil else { return false }
        case .deleted:
            guard deleted.validatingFields() != nil else { return false }
        case .edited:
            guard edited.validatingFields() != nil else { return false }
        case .confirmation:
            guard confirmation.validatingFields() != nil else { return false }
        case .reaction:
            guard reaction.validatingFields() != nil else { return false }
        case .asset:
            guard asset.validatingFields() != nil else { return false }
        default:
            break
        }
        return true
    }
}

// MARK: - Text

public extension Text {
    func validatingFields() -> Text? {
        let validMentions = mentions.compactMap { $0.validatingFields() }
        guard validMentions.count == mentions.count else { return nil }
        return self
    }
}

// MARK: Quotes

public extension Quote {
    func validatingFields() -> Quote? {
        UUID.isValid(object: quotedMessageID) ? self : nil
    }
}

// MARK: Mention

public extension GenericMessageProtocol.Mention {
    func validatingFields() -> GenericMessageProtocol.Mention? {
        UUID.isValid(object: userID) ? self : nil
    }
}

// MARK: Last Read

public extension LastRead {
    func validatingFields() -> LastRead? {
        UUID.isValid(object: conversationID) ? self : nil
    }
}

// MARK: Cleared

public extension Cleared {
    func validatingFields() -> Cleared? {
        UUID.isValid(object: conversationID) ? self : nil
    }
}

// MARK: Message Hide

public extension MessageHide {
    func validatingFields() -> MessageHide? {
        guard UUID.isValid(object: conversationID) else { return nil }
        guard UUID.isValid(object: messageID) else { return nil }
        return self
    }
}

// MARK: Message Delete

public extension MessageDelete {
    func validatingFields() -> MessageDelete? {
        UUID.isValid(object: messageID) ? self : nil
    }
}

// MARK: Message Edit

public extension MessageEdit {
    func validatingFields() -> MessageEdit? {
        UUID.isValid(object: replacingMessageID) ? self : nil
    }
}

// MARK: Message Confirmation

public extension Confirmation {
    func validatingFields() -> Confirmation? {
        guard UUID.isValid(object: firstMessageID) else { return nil }

        if !moreMessageIds.isEmpty {
            guard UUID.isValid(array: moreMessageIds) else { return nil }
        }

        return self
    }
}

// MARK: Reaction

public extension GenericMessageProtocol.Reaction {
    func validatingFields() -> GenericMessageProtocol.Reaction? {
        UUID.isValid(object: messageID) ? self : nil
    }
}

// MARK: User ID

public extension GenericMessageProtocol.Proteus_UserId {
    func validatingFields() -> GenericMessageProtocol.Proteus_UserId? {
        UUID.isValid(bytes: uuid) ? self : nil
    }
}

// MARK: - Asset

public extension GenericMessageProtocol.Asset {
    func validatingFields() -> GenericMessageProtocol.Asset? {
        if hasPreview, preview.hasRemote {
            guard preview.remote.validatingFields() != nil else { return nil }
        }

        if case .uploaded? = status {
            guard uploaded.validatingFields() != nil else { return nil }
        }

        return self
    }
}

public extension GenericMessageProtocol.Asset.RemoteData {
    func validatingFields() -> GenericMessageProtocol.Asset.RemoteData? {
        guard assetID.isValidAssetID else { return nil }
        guard assetToken.isValidBearerToken else { return nil }
        return self
    }
}
