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
import WireMainNavigationUI

// Manually created mock since sourcery: AutoMockable didn't work with associatedtypes.

final class MockMainCoordinatorProtocol: MainCoordinatorProtocol {
    typealias Dependencies = MockMainCoordinatorDependencies

    var showConversationList_Invocations: [ConversationFilter?] = []
    func showConversationList(conversationFilter: ConversationFilter?) async {
        showConversationList_Invocations += [conversationFilter]
    }

    var showArchive_Invocations: [Void] = []
    func showArchive() async {
        showArchive_Invocations.append(())
    }

    var showSettings_Invocations: [Void] = []
    func showSettings() async {
        showSettings_Invocations.append(())
    }

    var showConversation_Invocations: [(conversation: ConversationModel, message: ConversationMessageModel?)] = []
    func showConversation(conversation: ConversationModel, message: ConversationMessageModel?) async {
        showConversation_Invocations += [(conversation, message)]
    }

    var hideConversation_Invocations: [Void] = []
    func hideConversation() {
        hideConversation_Invocations.append(())
    }

    var showSettingsContent_Invocations: [SettingsTopLevelMenuItem] = []
    func showSettingsContent(_ topLevelMenuItem: SettingsTopLevelMenuItem) {
        showSettingsContent_Invocations += [topLevelMenuItem]
    }

    var hideSettingsContent_Invocations: [Void] = []
    func hideSettingsContent() {
        hideSettingsContent_Invocations.append(())
    }

    var presentViewController_Invocations: [UIViewController] = []
    func presentViewController(_ viewController: UIViewController) async {
        presentViewController_Invocations += [viewController]
    }

    var dismissPresentedViewController_Invocations: [Void] = []
    func dismissPresentedViewController() async {
        dismissPresentedViewController_Invocations.append(())
    }
}
