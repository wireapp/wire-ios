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

/// A common base for the split view controller and the tab bar controller.
@MainActor
public protocol MainContainerViewController: UIViewController {

    associatedtype ConversationList: MainConversationListProtocol
    associatedtype Archive: UIViewController
    associatedtype Settings: MainSettingsProtocol

    associatedtype Conversation: MainConversationProtocol
    associatedtype SettingsContent: MainSettingsContentProtocol

    associatedtype Connect: UIViewController // TODO: is it needed?

    // These three properties represent the tabs of the main tab bar controller.
    var conversationList: ConversationList? { get set }
    var archive: Archive? { get set }
    var settings: Settings? { get set }

    // These two represent the content, which will be pushed on the three main screens.
    var conversation: Conversation? { get set }
    var settingsContent: SettingsContent? { get set }

    func setConversationList(_ conversationList: ConversationList?, animated: Bool)
    func setArchive(_ archive: Archive?, animated: Bool)
    func setSettings(_ settings: Settings?, animated: Bool)

    func setConversation(_ conversation: Conversation?, animated: Bool)
    func setSettingsContent(_ settingsContent: SettingsContent?, animated: Bool)
}
