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
import WireSettings
import WireSyncEngine

@testable import Wire

@MainActor
final class MockMainCoordinator: MainCoordinatorProtocol {

    typealias ConversationList = ConversationListViewController
    typealias ConversationBuilder = ConversationViewControllerBuilder
    typealias Settings = UIViewController
    typealias SettingsContentBuilder = SettingsViewControllerBuilder
    typealias UserProfileBuilder = UserProfileViewControllerBuilder

    func showConversationList(conversationFilter: ConversationFilter?) {
        fatalError("Mock method not implemented")
    }

    func showArchive() {
        fatalError("Mock method not implemented")
    }

    func showSettings() {
        fatalError("Mock method not implemented")
    }

    func showConversation(conversation: ZMConversation, message: ZMConversationMessage?) async {
        fatalError("Mock method not implemented")
    }

    func hideConversation() {
        fatalError("Mock method not implemented")
    }

    func showSettingsContent(_: SettingsContentBuilder.TopLevelMenuItem) {
        fatalError("Mock method not implemented")
    }

    func hideSettingsContent() {
        fatalError("Mock method not implemented")
    }

    func showSelfProfile() {
        fatalError("Mock method not implemented")
    }

    func showUserProfile(user: any UserType) async {
        fatalError("Mock method not implemented")
    }

    func showConnect() {
        fatalError("Mock method not implemented")
    }

    func presentViewController(_ viewController: UIViewController) async {
        fatalError("Mock method not implemented")
    }
}

// MARK: - MainCoordinatorProtocol + MockMainCoordinator

extension MainCoordinatorProtocol where Self == MockMainCoordinator {
    @MainActor
    static var mock: Self { .init() }
}
