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
public import UIKit
import WireMessagingDomain

public enum MessagesSection: Sendable {
    case main
}

public typealias MessagesSnapshot = NSDiffableDataSourceSnapshot<MessagesSection, MessageType>

public protocol ConversationMessagesDataSourceProtocol: Sendable {
    func updatesStream() async -> AsyncStream<MessageUpdateType>
    func loadInitialMessages() async
}

/// Actor to synchronise access to all that needed to conversation screen
/// Does all calculations in background
public actor ConversationMessagesDataSource: @preconcurrency ConversationMessagesDataSourceProtocol {
    
    private var updatesStreamContinuation: AsyncStream<MessageUpdateType>.Continuation?
    public func updatesStream() async -> AsyncStream<MessageUpdateType> {
        return AsyncStream { continuation in
            self.updatesStreamContinuation = continuation
        }
    }

    public init() {
        
    }
    
    // store cached message view models
    private var messages: [MessageType] = []
    private var snapshot = MessagesSnapshot()
    
    // performs search
    func search(queries: [String]) {
        
    }
    
    // reset whole content when e.g. contentWidth is changed
    // in result whole content is recalculated since environment changes
    func invalidateContent() {
        
    }
    
    public func loadInitialMessages() async {
#if DEBUG
        generateMessages()
        simulateAddingMessage()
        Task {
            await timerLoop()
        }
#endif
        snapshot.appendSections([.main])
        snapshot.appendItems(messages)
        updatesStreamContinuation?.yield(.initiallyLoaded(snapshot))
    }
    
    // load message near some other provided message
    func loadMessages(
        near message: MessageModel,
        forceRecalculate: Bool = false,
    ) async -> IndexPath {
        return .init()
    }
    
    // load older messages
    func loadOlderMessages() {
        
    }
    
    // load newer messages
    func loadNewerMessages() {
        
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
        
    }
    
#if DEBUG
    func generateMessages() {
        let base = "This is a line. "
        messages = (0..<7).map { _ in
            let repeatCount = Int.random(in: 1...5)
            return .text(TextMessageViewModel(
                content: AttributedString(
                    stringLiteral: String(
                        repeating: base,
                        count: repeatCount
                    )),
                senderViewModel: Bool.random() ?
                SenderViewModel(state: .exists("Sender")) : SenderViewModel(state: .empty)
            ))
        }
    }
    
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
    private func timerLoop() async {
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
        
        guard let message = messages.randomElement(),
              case let .text(randomVM) = message else {
            return
        }
        let base = "Updated line. "
        DispatchQueue.main.async {
            let repeatCount = Int.random(in: 1...6)
            randomVM.content = AttributedString(
                stringLiteral: String(repeating: base, count: repeatCount))
            let updateSenderAttributed = AttributedString(stringLiteral: String(
                repeating: "Updated Sender",
                count: repeatCount
            ))
            randomVM.senderViewModel.state = Bool.random() ? SenderViewModel.State.exists(updateSenderAttributed) : SenderViewModel.State.empty
            
        }
        
        guard let message = self.messages.randomElement(),
              case let .text(randomVM2) = message else {
            return
        }
        DispatchQueue.main.async {
            let repeatCount = Int.random(in: 1...6)
            randomVM2.content = AttributedString(
                stringLiteral: String(repeating: base, count: repeatCount))
            let updateSenderAttributed2 = AttributedString(stringLiteral: String(
                repeating: "Updated Sender",
                count: repeatCount
            ))
            randomVM2.senderViewModel.state = Bool.random() ? SenderViewModel.State.exists(updateSenderAttributed2) : SenderViewModel.State.empty
        }
        
        
        guard let message = self.messages.randomElement(),
              case let .text(randomVM3) = message else {
            return
        }
        DispatchQueue.main.async {
            let repeatCount = Int.random(in: 1...6)
            
            randomVM3.content = AttributedString(
                stringLiteral: String(repeating: base, count: repeatCount))
            let updateSenderAttributed3 = AttributedString(stringLiteral: String(
                repeating: "Updated Sender",
                count: repeatCount
            ))
            randomVM3.senderViewModel.state = Bool.random() ? SenderViewModel.State.exists(updateSenderAttributed3) : SenderViewModel.State.empty
        }
    }
    
#endif
    
}
