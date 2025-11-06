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
package protocol ConversationMessagesViewModelProtocol {
    func makeUpdatesStream() async -> AsyncStream<MessagesUpdate>
    func onViewReady()
    func onWillDisappear()
}

@MainActor
// Not much doing at the moment, will be more later
// One of the main responsibilities is being MainActor to serve view
// since DataSource is actor and works on background thread
package struct ConversationMessagesViewModel: ConversationMessagesViewModelProtocol {

    private let dataSource: any ConversationDataSourceProtocol

    package init(dataSource: any ConversationDataSourceProtocol) {
        self.dataSource = dataSource
    }

    package func makeUpdatesStream() async -> AsyncStream<MessagesUpdate> {
        await dataSource.makeUpdatesStream()
    }

    package func onViewReady() {
        Task { [dataSource] in
            await dataSource.loadInitialMessages()
        }
    }

    package func onWillDisappear() {
        Task { [dataSource] in
            await dataSource.reset()
        }
    }
}
