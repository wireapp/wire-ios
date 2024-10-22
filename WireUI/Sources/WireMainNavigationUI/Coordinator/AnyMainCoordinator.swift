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

import UIKit

/// A type-erased MainCoordinator.
public final class AnyMainCoordinator<Dependencies: MainCoordinatorDependencies>: MainCoordinatorProtocol {

    public let base: any MainCoordinatorProtocol

    private let _showConversationList: @MainActor (_ conversationFilter: ConversationFilter?) async -> Void
    private let _showArchive: @MainActor () async -> Void
    private let _showSettings: @MainActor () async -> Void
    private let _showConversation: @MainActor (_ conversation: ConversationModel, _ message: ConversationMessageModel?) async -> Void
    private let _hideConversation: @MainActor () -> Void
    private let _showSettingsContent: @MainActor (_ topLevelMenuItem: SettingsTopLevelMenuItem) -> Void
    private let _hideSettingsContent: @MainActor () -> Void
    private let _showConnect: @MainActor () async -> Void
    private let _showCreateGroupConversation: @MainActor () async -> Void
    private let _presentViewController: @MainActor (_ viewController: UIViewController) async -> Void
    private let _dismissPresentedViewController: @MainActor () async -> Void

    @MainActor
    public init<MainCoordinator: MainCoordinatorProtocol>(
        mainCoordinator: MainCoordinator
    ) where MainCoordinator.Dependencies == Dependencies {
        base = mainCoordinator
        _showConversationList = { conversationFilter in
            await mainCoordinator.showConversationList(conversationFilter: conversationFilter)
        }
        _showArchive = {
            await mainCoordinator.showArchive()
        }
        _showSettings = {
            await mainCoordinator.showSettings()
        }
        _showConversation = { conversation, message in
            await mainCoordinator.showConversation(conversation: conversation, message: message)
        }
        _hideConversation = {
            mainCoordinator.hideConversation()
        }
        _showSettingsContent = { topLevelMenuItem in
            mainCoordinator.showSettingsContent(topLevelMenuItem)
        }
        _hideSettingsContent = {
            mainCoordinator.hideSettingsContent()
        }
        _showConnect = {
            await mainCoordinator.showConnect()
        }
        _showCreateGroupConversation = {
            await mainCoordinator.showCreateGroupConversation()
        }
        _presentViewController = { viewController in
            await mainCoordinator.presentViewController(viewController)
        }
        _dismissPresentedViewController = {
            await mainCoordinator.dismissPresentedViewController()
        }
    }

    @MainActor
    public func showConversationList(conversationFilter: ConversationFilter?) async {
        await _showConversationList(conversationFilter)
    }

    @MainActor
    public func showArchive() async {
        await _showArchive()
    }

    @MainActor
    public func showSettings() async {
        await _showSettings()
    }

    @MainActor
    public func showConversation(conversation: ConversationModel, message: ConversationMessageModel?) async {
        await _showConversation(conversation, message)
    }

    @MainActor
    public func hideConversation() {
        _hideConversation()
    }

    @MainActor
    public func showSettingsContent(_ topLevelMenuItem: SettingsTopLevelMenuItem) {
        _showSettingsContent(topLevelMenuItem)
    }

    @MainActor
    public func hideSettingsContent() {
        _hideSettingsContent()
    }

    @MainActor
    public func showConnect() async {
        await _showConnect()
    }

    @MainActor
    public func showCreateGroupConversation() async {
        await _showCreateGroupConversation()
    }

    @MainActor
    public func presentViewController(_ viewController: UIViewController) async {
        await _presentViewController(viewController)
    }

    @MainActor
    public func dismissPresentedViewController() async {
        await _dismissPresentedViewController()
    }
}
