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

public protocol MainCoordinatorDependencies: MainCoordinatorProtocolDependencies {

    associatedtype SplitViewController: MainSplitViewControllerProtocol where
        SplitViewController.TabBarController.ConversationListUI.ConversationFilter == ConversationFilter,
        SplitViewController.TabBarController.ConversationListUI.ConversationModel == ConversationModel

    associatedtype ConversationUIBuilder: MainConversationUIBuilderProtocol where
        ConversationUIBuilder.Dependencies == Self,
        ConversationUIBuilder.ConversationUI == SplitViewController.ConversationUI

    associatedtype SettingsContentUIBuilder: MainSettingsContentUIBuilderProtocol where
        SettingsContentUIBuilder.TopLevelMenuItem == SettingsTopLevelMenuItem

    associatedtype ConnectUIBuilder: MainCoordinatorInjectingViewControllerBuilder where
        ConnectUIBuilder.Dependencies == Self

    associatedtype CreateGroupConversationUIBuilder: MainCoordinatorInjectingViewControllerBuilder where
        CreateGroupConversationUIBuilder.Dependencies == Self

    associatedtype SelfProfileUIBuilder: MainCoordinatorInjectingViewControllerBuilder where
        SelfProfileUIBuilder.Dependencies == Self
}
