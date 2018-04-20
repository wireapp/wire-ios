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

    fileprivate static func isValid(object: Any?) -> Bool {
        guard let string = object as? String else { return false }
        return UUID(uuidString: string) != nil
    }

    fileprivate static func isValid(bytes: Data?) -> Bool {
        return bytes?.count == 16
    }

    fileprivate static func isValid(array: [Any]?) -> Bool {
        return array?.map(UUID.isValid).contains(false) == false
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

        // Validate the reaction
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

        if let mentions = self.mention {
            let validMentions = mentions.flatMap { $0.validatingFields() }
            guard validMentions.count == mentions.count else { return nil }
        }

        return self

    }
}

extension ZMTextBuilder {
    @objc public func buildAndValidate() -> ZMText? {
        return self.build()?.validatingFields()
    }
}

// MARK: Mention

extension ZMMention {
    @objc public func validatingFields() -> ZMMention? {
        guard UUID.isValid(object: userId) else { return nil }
        return self
    }
}

extension ZMMentionBuilder {
    @objc public func buildAndValidate() -> ZMMention? {
        return self.build()?.validatingFields()
    }
}

// MARK: Last Read

extension ZMLastRead {
    @objc public func validatingFields() -> ZMLastRead? {
        guard UUID.isValid(object: conversationId) else { return nil }
        return self
    }
}

extension ZMLastReadBuilder {
    @objc public func buildAndValidate() -> ZMLastRead? {
        return self.build()?.validatingFields()
    }
}

// MARK: Cleared

extension ZMCleared {
    @objc public func validatingFields() -> ZMCleared? {
        guard UUID.isValid(object: conversationId) else { return nil }
        return self
    }
}

extension ZMClearedBuilder {
    @objc public func buildAndValidate() -> ZMCleared? {
        return self.build()?.validatingFields()
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

extension ZMMessageHideBuilder {
    @objc public func buildAndValidate() -> ZMMessageHide? {
        return self.build()?.validatingFields()
    }
}

// MARK: Message Delete

extension ZMMessageDelete {
    @objc public func validatingFields() -> ZMMessageDelete? {
        guard UUID.isValid(object: messageId) else { return nil }
        return self
    }
}

extension ZMMessageDeleteBuilder {
    @objc public func buildAndValidate() -> ZMMessageDelete? {
        return self.build()?.validatingFields()
    }
}

// MARK: Message Edit

extension ZMMessageEdit {
    @objc public func validatingFields() -> ZMMessageEdit? {
        guard UUID.isValid(object: replacingMessageId) else { return nil }
        return self
    }
}

extension ZMMessageEditBuilder {
    @objc public func buildAndValidate() -> ZMMessageEdit? {
        return self.build()?.validatingFields()
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

extension ZMConfirmationBuilder {
    @objc public func buildAndValidate() -> ZMConfirmation? {
        return self.build()?.validatingFields()
    }
}

// MARK: - Asset

extension ZMAsset {
    @objc public func validatingFields() -> ZMAsset? {
        if self.hasUploaded() {
            guard self.uploaded!.validatingFields() != nil else { return nil }
        }
        return self
    }
}

extension ZMAssetBuilder {
    @objc public func buildAndValidate() -> ZMAsset? {
        return self.build()?.validatingFields()
    }
}

// MARK: Asset Remote Data

extension ZMAssetRemoteData {
    @objc public func validatingFields() -> ZMAssetRemoteData? {
        guard UUID.isValid(object: assetId) else { return nil }
        return self
    }
}

extension ZMAssetRemoteDataBuilder {
    @objc public func buildAndValidate() -> ZMAssetRemoteData? {
        return self.build()?.validatingFields()
    }
}

// MARK: Reaction

extension ZMReaction {
    @objc public func validatingFields() -> ZMReaction? {
        guard UUID.isValid(object: messageId) else { return nil }
        return self
    }
}

extension ZMReactionBuilder {
    @objc public func buildAndValidate() -> ZMReaction? {
        return self.build()?.validatingFields()
    }
}

// MARK: User ID

extension ZMUserId {
    @objc public func validatingFields() -> ZMUserId? {
        guard UUID.isValid(bytes: uuid) else { return nil }
        return self
    }
}

extension ZMUserIdBuilder {
    @objc public func buildAndValidate() -> ZMUserId? {
        return self.build()?.validatingFields()
    }
}
