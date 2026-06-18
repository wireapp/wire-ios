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
    var progressState: MessageProgressState? { get }

    func send() async

}

public enum MessageProgressState {
    case preparing
    case sending(Float)
    case success
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
    public var progressState: MessageProgressState?

    private let router: RootRouter
    private let sendMessage: SendMessageUseCase
    private let onDone: () -> Void

    public init(
        account: Account,
        conversation: Conversation,
        shareItem: ShareItem,
        router: RootRouter,
        sendMessage: SendMessageUseCase,
        onDone: @escaping () -> Void
    ) {
        self.account = account
        self.conversation = conversation
        self.shareItem = shareItem
        self.router = router
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

        let sendMessageTask = Task.detached { [self] in
            try await sendMessage(
                message,
                for: account,
                in: conversation
            )
        }

        let progress: AsyncThrowingStream<MessageSendingProgress, any Error>
        do {
            progress = try await sendMessageTask.value
        } catch {
            router.errorAlert = .generic(message: "failed to send: \(error)")
            return
        }

        do {
            for try await update in progress {
                switch update {
                case .preparing:
                    progressState = .preparing
                case let .sending(progress):
                    progressState = .sending(progress)
                }
            }
            
            progressState = .success
            
            try await Task.sleep(for: .seconds(1))
            
            progressState = nil
            onDone()
        } catch let error as MessageSendingError {
            switch error {
            case .timedOut:
                router.errorAlert = .generic(message: "Timed out")
            case .conversationDegraded:
                router.errorAlert = .generic(message: "Conversation is degraded")
            case .fileSharingDisabled:
                router.errorAlert = .generic(message: "File sharing is disabled")
            case let .generic(error):
                router.errorAlert = .generic(message: "Something went wrong")
            }
        } catch {
            router.errorAlert = .generic(message: "Something went wrong")
        }
    }

}
