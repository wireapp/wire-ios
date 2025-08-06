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

@MainActor
public protocol ConversationMessagesViewModelProtocol {
    func updatesStream() async -> AsyncStream<MessagesUpdate>
    func onViewReady()
}

@MainActor
// Not much doing at the moment, will be more later
// One of the main responsibilities is being MainActor to serve view
public struct ConversationMessagesViewModel: ConversationMessagesViewModelProtocol {

    private let dataSource: any ConversationMessagesDataSourceProtocol

    public init(dataSource: any ConversationMessagesDataSourceProtocol) {
        self.dataSource = dataSource
    }

    public func updatesStream() async -> AsyncStream<MessagesUpdate> {
        await dataSource.updatesStream()
    }

    public func onViewReady() {
        Task {
            await dataSource.loadInitialMessages()
        }
    }
}
