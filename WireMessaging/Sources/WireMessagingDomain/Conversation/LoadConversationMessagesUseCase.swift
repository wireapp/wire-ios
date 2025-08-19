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

public import Foundation

public protocol LoadConversationMessagesRepositoryProtocol: Sendable {
    var hasOlderMessagesToLoad: Bool { get }
    func loadMessages(offset: Int) async -> [MessageModel]
    func loadOlderMessages(lastMessageTimestamp: Date) async -> [MessageModel]
}

public let kLoadMessagesDefaultBatchSize = 30

// sourcery: AutoMockable
package protocol LoadConversationMessagesUseCaseProtocol: Sendable {
    var hasOlderMessagesToLoad: Bool { get }
    func loadMessages(offset: Int) async -> [MessageModel]
    func loadOlderMessages(lastMessageTimestamp: Date) async -> [MessageModel]
}

package final class LoadConversationMessagesUseCase: LoadConversationMessagesUseCaseProtocol {

    private let repo: any LoadConversationMessagesRepositoryProtocol
    
    package var hasOlderMessagesToLoad: Bool { repo.hasOlderMessagesToLoad }

    package init(repo: any LoadConversationMessagesRepositoryProtocol) {
        self.repo = repo
    }

    package func loadMessages(offset: Int) async -> [MessageModel] {
        await repo.loadMessages(offset: offset)
    }
    
    package func loadOlderMessages(lastMessageTimestamp: Date) async -> [MessageModel] {
        await repo.loadOlderMessages(lastMessageTimestamp: lastMessageTimestamp)
    }
    
}
