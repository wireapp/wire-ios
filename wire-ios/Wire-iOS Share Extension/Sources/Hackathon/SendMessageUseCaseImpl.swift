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
import WireShareEngine
import WireShareExtensionCore

struct SendMessageUseCaseImpl: SendMessageUseCase {

    let sessionProvider: (Account) async throws -> SharingSession

    // FIXME: this is just a temp workaround to work with existing
    // code.
    let attachments: [NSItemProvider]

    private let postContent: PostContent

    init(
        sessionProvider: @escaping (
            Account
        ) async throws -> SharingSession,
        attachments: [NSItemProvider]
    ) {
        self.sessionProvider = sessionProvider
        self.attachments = attachments
        postContent = PostContent(attachments: attachments)
    }

    func callAsFunction(
        _ message: Message,
        for account: Account,
        in conversation: WireShareExtensionCore.Conversation
    ) async throws -> AsyncThrowingStream<MessageSendingProgress, Error> {
        let session = try await sessionProvider(account)

        guard let target = session.writeableNonArchivedConversations.first(where: {
            $0.remoteIdentifier == conversation.id
        }) else {
            fatalError()
        }

        postContent.target = target

        return AsyncThrowingStream { continuation in
            postContent.send(
                text: message.text ?? "",
                sharingSession: session
            ) {
                switch $0 {
                case .preparing:
                    continuation.yield(.preparing)
                case .startingSending:
                    continuation.yield(.sending(0))
                case let .sending(progress):
                    continuation.yield(.sending(progress))
                case .done:
                    continuation.finish()
                case .fileSharingRestriction:
                    continuation.finish(throwing: MessageSendingError.fileSharingDisabled)
                case .timedOut:
                    continuation.finish(throwing: MessageSendingError.timedOut)
                case .conversationDidDegrade:
                    continuation.finish(throwing: MessageSendingError.conversationDegraded)
                case let .error(error):
                    continuation.finish(throwing: MessageSendingError.generic(error))
                }
            }
        }
    }

}
