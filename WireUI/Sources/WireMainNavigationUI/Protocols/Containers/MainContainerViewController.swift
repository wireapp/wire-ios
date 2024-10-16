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
public protocol MainContainerViewControllerProtocol: UIViewController {

    associatedtype ConversationListUI: MainConversationListUIProtocol
    associatedtype ArchiveUI: UIViewController
    associatedtype SettingsUI: UIViewController

    associatedtype ConversationUI: MainConversationUIProtocol

    // These three properties represent the tabs of the main tab bar controller.
    var conversationListUI: ConversationListUI? { get set }
    var archiveUI: ArchiveUI? { get set }
    var settingsUI: SettingsUI? { get set }

    // These two represent the content, which will be pushed on the three main screens.
    var conversationUI: ConversationUI? { get set }
    var settingsContentUI: UIViewController? { get set }
}
