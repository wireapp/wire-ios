//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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
package import UIKit
package import WireMessagingDomain

package enum MessagesSection: Sendable {
    // one section for now, later we'd have probably one section for a day
    case main
}

package typealias MessagesSnapshot = NSDiffableDataSourceSnapshot<MessagesSection, MessageType>

package protocol ConversationMessagesDataSourceProtocol: Sendable {
    func updatesStream() async -> AsyncStream<MessagesUpdate>
    func loadInitialMessages() async
}

/// Actor to synchronise access to all that needed to conversation screen
/// Does all calculations in background
package actor ConversationMessagesDataSource: @preconcurrency ConversationMessagesDataSourceProtocol {

    // AsyncStream because Combine's AnyPublisher is not Sendable
    private var updatesStreamContinuation: AsyncStream<MessagesUpdate>.Continuation?
    package func updatesStream() async -> AsyncStream<MessagesUpdate> {
        AsyncStream { continuation in
            self.updatesStreamContinuation = continuation
        }
    }
    
    private let loadMessagesUseCase: any LoadConversationMessagesUseCaseProtocol

    // here on later stages will be injected uses cases and
    // provider to ask for publishers needed for View Models
    package init(loadMessagesUseCase: any LoadConversationMessagesUseCaseProtocol) {
        self.loadMessagesUseCase = loadMessagesUseCase
    }

    // store cached message view models
    private var messages: [MessageType] = []
    private var snapshot = MessagesSnapshot()

    // performs search
    func search(queries: [String]) {}

    // reset whole content when e.g. contentWidth is changed
    // in result whole content is recalculated since environment changes
    func invalidateContent() {}

    package func loadInitialMessages() async {
        #if DEBUG
            simulateAddingMessage()
            Task {
                await updatesTimerLoop()
            }
        #endif
        let messages = await loadMessagesUseCase.loadMessages(offset: 0, limit: 100)
        
        snapshot.appendSections([.main])
        snapshot.appendItems(messages.toUIModel())
        updatesStreamContinuation?.yield(.initiallyLoaded(snapshot))
    }

    // load message near some other provided message
    func loadMessages(
        near message: MessageModel,
        forceRecalculate: Bool = false,
    ) async -> IndexPath {
        .init()
    }

    // load older messages
    func loadOlderMessages() {}

    // load newer messages
    func loadNewerMessages() {}

    // MARK: - private

    private func loadMessages(
        offset: Int = 0,
        limit: Int = 30
    ) async {
        // call use case to get new messages
        // map domain level entities to view models
        // cache them
        // post process (group) if needed
        // make a diffable snapshot and emit to a client
    }

    // MARK: - Handle notifications about something changed

    // here will be subscribed to any messages updates notifications
    // and start processing them
    private func subscribeToNotifications() {}

    #if DEBUG
        // Temp Dev code

        private func simulateAddingMessage() {
            Task {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                let message: MessageType =
                    .text(TextMessageViewModel(
                        content: AttributedString(stringLiteral: "New message added"),
                        senderViewModel: Bool.random() ?
                            SenderViewModel(state: .exists("Sender")) : SenderViewModel(state: .empty)
                    ))
                messages.append(message)
                snapshot.appendItems([message])
                updatesStreamContinuation?.yield(.messageAdded(snapshot))
            }
        }

        private var isRunning = true
        private func updatesTimerLoop() async {
            Task {
                try? await Task.sleep(nanoseconds: 10_000_000_000)
                isRunning = false
            }

            while isRunning {
                // Do your actor-safe update
                performRandomUpdate()

                // Sleep for 2 seconds (2_000_000_000 nanoseconds)
                try? await Task.sleep(nanoseconds: 2_000_000_000)
            }
        }

        private func performRandomUpdate() {
            guard let message = messages.randomElement(), case let .text(randomVM) = message else {
                return
            }
            DispatchQueue.main.async {
                let base = "Updated line. "
                let repeatCount = Int.random(in: 1 ... 6)
                randomVM.content = AttributedString(stringLiteral: String(repeating: base, count: repeatCount))
                let updateSenderAttributed = AttributedString(
                    stringLiteral: String(repeating: "Updated Sender", count: repeatCount)
                )
                randomVM.senderViewModel.state = Bool.random() ? SenderViewModel.State
                    .exists(updateSenderAttributed) : SenderViewModel.State.empty
            }
        }

    #endif

}

extension Array where Element == MessageModel {
    func toUIModel() -> [MessageType] {
        map { model in
            switch model.kind {
            case let .text(textModel):
                MessageType.text(
                    TextMessageViewModel(
                        content: AttributedString(stringLiteral: textModel.text ?? ""),
                        senderViewModel: Bool.random() ?
                        SenderViewModel(state: .exists(AttributedString(
                            stringLiteral: model.sender?
                                .name ?? ""
                        ))) : SenderViewModel(
                            state: .empty
                        )
                    )
                )
            default: fatalError()
            }
        }
    }
}
