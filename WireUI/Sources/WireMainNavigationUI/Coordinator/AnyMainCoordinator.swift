//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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
public final class AnyMainCoordinator<Dependencies: MainCoordinatorDependenciesProtocol>: MainCoordinatorProtocol {

    public let base: any MainCoordinatorProtocol

    private let _showConversationList: @MainActor (_ conversationFilter: ConversationFilter?) async -> Void
    private let _applyConversationFilter: @MainActor (_ conversationFilter: ConversationFilter?) -> Void
    private let _showArchive: @MainActor () async -> Void
    private let _showSettings: @MainActor () async -> Void
    private let _showMeetings: @MainActor () async -> Void
    private let _showFiles: @MainActor () async -> Void
    private let _showConversation: @MainActor (
        _ conversation: ConversationModel,
        _ message: ConversationMessageModel?
    ) async -> Void
    private let _hideConversation: @MainActor () -> Void
    private let _showSettingsContent: @MainActor (_ topLevelMenuItem: SettingsTopLevelMenuItem) -> Void
    private let _hideSettingsContent: @MainActor () -> Void
    private let _presentViewController: @MainActor (_ viewController: UIViewController) async -> Void
    private let _dismissPresentedViewController: @MainActor () async -> Void

    @MainActor
    public init<MainCoordinator: MainCoordinatorProtocol>(
        mainCoordinator: MainCoordinator
    ) where MainCoordinator.Dependencies == Dependencies {
        self.base = mainCoordinator
        self._showConversationList = { conversationFilter in
            await mainCoordinator.showConversationList(conversationFilter: conversationFilter)
        }
        self._applyConversationFilter = { conversationFilter in
            mainCoordinator.applyConversationFilter(conversationFilter)
        }
        self._showArchive = {
            await mainCoordinator.showArchive()
        }
        self._showSettings = {
            await mainCoordinator.showSettings()
        }
        self._showMeetings = {
            await mainCoordinator.showMeetings()
        }
        self._showFiles = {
            await mainCoordinator.showFiles()
        }
        self._showConversation = { conversation, message in
            await mainCoordinator.showConversation(conversation: conversation, message: message)
        }
        self._hideConversation = {
            mainCoordinator.hideConversation()
        }
        self._showSettingsContent = { topLevelMenuItem in
            mainCoordinator.showSettingsContent(topLevelMenuItem)
        }
        self._hideSettingsContent = {
            mainCoordinator.hideSettingsContent()
        }
        self._presentViewController = { viewController in
            await mainCoordinator.presentViewController(viewController)
        }
        self._dismissPresentedViewController = {
            await mainCoordinator.dismissPresentedViewController()
        }
    }

    @MainActor
    public func showConversationList(conversationFilter: ConversationFilter?) async {
        await _showConversationList(conversationFilter)
    }

    @MainActor
    public func applyConversationFilter(_ conversationFilter: ConversationFilter?) {
        _applyConversationFilter(conversationFilter)
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
    public func showMeetings() async {
        await _showMeetings()
    }

    @MainActor
    public func showFiles() async {
        await _showFiles()
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
    public func presentViewController(_ viewController: UIViewController) async {
        await _presentViewController(viewController)
    }

    @MainActor
    public func dismissPresentedViewController() async {
        await _dismissPresentedViewController()
    }
}
