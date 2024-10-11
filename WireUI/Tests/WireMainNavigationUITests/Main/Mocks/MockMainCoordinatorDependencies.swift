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

@testable import WireMainNavigationUI

enum MockMainCoordinatorDependencies: MainCoordinatorDependencies {

    // MainCoordinatorProtocolDependencies

    typealias ConversationFilter = MainConversationFilter
    typealias ConversationModel = PreviewConversationModel
    typealias ConversationMessageModel = MockConversationMessageModel
    typealias SettingsTopLevelMenuItem = MainSettingsTopLevelMenuItem
    typealias User = MockUser

    // MainCoordinatorDependencies

    typealias SplitViewController = MockSplitViewController
    typealias ConversationBuilder = MockConversationBuilder
    typealias SettingsContentBuilder = MockSettingsViewControllerBuilder
    typealias ConnectBuilder = MockViewControllerBuilder
    typealias CreateGroupConversationBuilder = MockViewControllerBuilder
    typealias SelfProfileBuilder = MockViewControllerBuilder
    typealias UserProfileBuilder = MockUserProfileViewControllerBuilder
}
