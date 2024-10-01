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

public protocol MessageAppendableConversation {

    var conversationType: ZMConversationType { get }
    var localParticipants: Set<ZMUser> { get }
    var draftMessage: DraftMessage? { get nonmutating set }

    @discardableResult
    func appendText(
        content: String,
        mentions: [Mention],
        replyingTo quotedMessage: (any ZMConversationMessage)?,
        fetchLinkPreview: Bool,
        nonce: UUID
    ) throws -> any ZMConversationMessage

    @discardableResult
    func appendKnock(nonce: UUID) throws -> any ZMConversationMessage

    @discardableResult
    func appendImage(from imageData: Data, nonce: UUID) throws -> any ZMConversationMessage

    @discardableResult
    func appendLocation(with locationData: LocationData, nonce: UUID) throws -> ZMConversationMessage

    @discardableResult
    func appendFile(
        with fileMetadata: ZMFileMetadata,
        nonce: UUID
    ) throws -> ZMConversationMessage

}

extension ZMConversation: MessageAppendableConversation {

    

}
