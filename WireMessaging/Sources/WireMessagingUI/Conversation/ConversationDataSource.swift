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

import Combine
import Foundation
package import UIKit
package import WireMessagingDomain
package import WireLogging

package enum ConversationSection: Sendable {
    // one section for now, later we'd have probably one section for a day
    case main
}

package typealias ConversationSnapshot = NSDiffableDataSourceSnapshot<ConversationSection, ConversationElement>

package protocol ConversationDataSourceProtocol: Sendable {
    func makeUpdatesStream() async -> AsyncStream<MessagesUpdate>
    func loadInitialMessages() async
    func reset() async
    func loadOlderMessages() async
    func loadNewerMessages() async
}

/// Actor to synchronise access to all that needed to conversation screen
/// Does all calculations in background
package actor ConversationDataSource: @preconcurrency ConversationDataSourceProtocol {

    // AsyncStream because Combine's AnyPublisher is not Sendable
    // As it's a stream, has to be one subscriber only
    private var updatesStreamContinuation: AsyncStream<MessagesUpdate>.Continuation?
    package func makeUpdatesStream() async -> AsyncStream<MessagesUpdate> {
        let (stream, continuation) = AsyncStream.makeStream(of: MessagesUpdate.self)
        updatesStreamContinuation = continuation
        return stream
    }

    private let loadMessagesUseCase: any LoadConversationMessagesUseCaseProtocol
    private let monitorMessagesUseCase: any MonitorMessagesUseCaseProtocol
    private let observersProvider: AnyObserverProvider

    // here on later stages will be injected uses cases and
    // provider to ask for publishers needed for View Models
    package init(
        loadMessagesUseCase: any LoadConversationMessagesUseCaseProtocol,
        monitorMessagesUseCase: any MonitorMessagesUseCaseProtocol,
        observersProvider: AnyObserverProvider
    ) {
        self.loadMessagesUseCase = loadMessagesUseCase
        self.monitorMessagesUseCase = monitorMessagesUseCase
        self.observersProvider = observersProvider
    }

    // store cached message view models
    private var snapshot = ConversationSnapshot()

    private var observeTask: Task<Void, Never>?

    // performs search
    func search(queries: [String]) {}

    // reset whole content when e.g. contentWidth is changed
    // in result whole content is recalculated since environment changes
    func invalidateContent() {}

    package func loadInitialMessages() async {
        let messages = await loadMessagesUseCase.loadMessages(offset: 0)

        snapshot.appendSections([.main])
        snapshot.appendItems(
            messages
                .reversed()
                .map { mapToUIModel($0) }
        )
        updatesStreamContinuation?.yield(.initiallyLoaded(snapshot))

        subscribeToNotifications()
    }

    private func observeChanges() async {
        for await event in monitorMessagesUseCase.messagesUpdatesStream {
            switch event {
            case let .inserted(model):
                let uiModel = mapToUIModel(model)
                snapshot.appendItems([uiModel])
                updatesStreamContinuation?.yield(.messageAdded(snapshot))
            }
        }
    }

    private func mapToUIModel(_ model: MessageModel) -> ConversationElement {
        switch model.kind {
        case let .text(textModel):
            let senderState: SenderViewModel.State = if let name = model.sender?.name {
                .exists(AttributedString(stringLiteral: name))
            } else {
                .empty
            }

            return ConversationElement.text(
                TextMessageViewModel(
                    content: AttributedString(stringLiteral: textModel.text ?? ""),
                    serverTimestamp: model.serverTimestamp,
                    senderViewModel: SenderViewModel(
                        state: senderState,
                        namePublisher: observersProvider
                            .senderNameObserverProvider?(model.sender)?.authorChangedPublisher
                    ),
                    reactionsViewModel: ReactionsViewModel(
                        state: ReactionsViewModel.state(from: model.reactions),
                        publisher: observersProvider.get(for: model)
                    )
                )
            )
        default: fatalError()
        }

    }

    package func reset() async {
        // Need to be called to clean up subscription and avoid memory leak
        observeTask?.cancel()
        observeTask = nil
    }

    // load message near some other provided message
    func loadMessages(
        near message: MessageModel,
        forceRecalculate: Bool = false,
    ) async -> IndexPath {
        .init()
    }

    // load older messages
    
    var loadingMessages = false
    var currentOffset = 0
    package func loadOlderMessages() async {
        guard !loadingMessages, loadMessagesUseCase.hasOlderMessagesToLoad else {
            print("DS: loadOlderMessages: guard already loading")
            updatesStreamContinuation?.yield(.noMoreMessagesToLoad)
            return
        }
        
        // NOTE: we dispatch async because `didScroll(tableView:)` can be called inside a `performBatchUpdate()`,
        // which would cause data source inconsistency if change the fetchLimit.
        
        guard let oldestMessageTimestamp = snapshot.itemIdentifiers.first(where: { $0.serverTimestamp != nil })?.serverTimestamp else {
            print("DS: loadOlderMessages: can't find oldest message")
            updatesStreamContinuation?.yield(.noMoreMessagesToLoad)
            return
        }
        
        loadingMessages = true
        let messages = await loadMessagesUseCase.loadOlderMessages(
            lastMessageTimestamp: oldestMessageTimestamp
        )
        guard messages.count > 0, let beforeItem = snapshot.itemIdentifiers.first else {
            WireLogger.conversation.error(
                "Failed to get beforeItem for snapshot.itemIdentifiers.first to insert new loaded messages")
            updatesStreamContinuation?.yield(.noMoreMessagesToLoad)
            return
        }
        
        snapshot.insertItems(
            messages
                .reversed()
                .map { mapToUIModel($0) },
            beforeItem: beforeItem
        )
        updatesStreamContinuation?.yield(.loadedOlderMessages(snapshot))

        loadingMessages = false
    }

    // load newer messages
    package func loadNewerMessages() {
        
    }

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

    private func subscribeToNotifications() {
        observeTask = Task { [weak self] in
            guard let self else { return }
            await observeChanges()
        }
    }

}
