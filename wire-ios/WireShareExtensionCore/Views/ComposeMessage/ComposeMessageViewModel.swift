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
import SwiftUI

@MainActor
protocol ComposeMessageViewModel {

    var conversation: Conversation { get }
    var shareItem: ShareItem { get }
    var messageText: String { get set }
    var canSend: Bool { get }
    var isLoading: Bool { get }

    func send() async

}

@Observable
@MainActor
public final class ComposeMessageViewModelImpl: ComposeMessageViewModel {

    public let account: Account
    public let conversation: Conversation
    public let shareItem: ShareItem
    public var messageText: String = ""

    public var canSend: Bool {
        true
    }

    public var isLoading: Bool = false
    private let onDone: () -> Void
    private let sendMessage: SendMessageUseCase

    public init(
        account: Account,
        conversation: Conversation,
        shareItem: ShareItem,
        sendMessage: SendMessageUseCase,
        onDone: @escaping () -> Void
    ) {
        self.account = account
        self.conversation = conversation
        self.shareItem = shareItem
        self.onDone = onDone
        self.sendMessage = sendMessage
    }

    public func send() async {
        isLoading = true
        defer { isLoading = false }
        
        let message = Message(
            text: messageText,
            shareItem: shareItem
        )

        do {
            try await sendMessage(message, for: account, in: conversation)
            onDone()
        } catch {
            // TODO: Handle
        }
    }

}
