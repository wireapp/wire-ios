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

import WireDataModel
import WireMainNavigation

@testable import Wire

final class MockMainCoordinator: MainCoordinatorProtocol {
    typealias ConversationList = ConversationListViewController
    typealias Settings = SettingsMainViewController

    func showConversationList(conversationFilter: ConversationFilter?) async {
        fatalError("Mock method not implemented")
    }

    func showConversationList(conversationFilter: ConversationFilter?, conversationID: UUID?) async {
        fatalError("Mock method not implemented")
    }

    func showConversationList(conversationFilter: ConversationFilter?, conversationID: UUID?, messageID: String?) async {
        fatalError("Mock method not implemented")
    }

    func showArchivedConversations() async {
        fatalError("Mock method not implemented")
    }

    func showSelfProfile() async {
        fatalError("Mock method not implemented")
    }

    func showSettings() async {
        fatalError("Mock method not implemented")
    }

    func showSettings(content: Settings.Content?) async {
        fatalError("Mock method not implemented")
    }

    func showConnect() async {
        fatalError("Mock method not implemented")
    }
}

// MARK: - MainCoordinatorProtocol + mock

extension MainCoordinatorProtocol where Self == MockMainCoordinator {
    static var mock: Self { .init() }
}
