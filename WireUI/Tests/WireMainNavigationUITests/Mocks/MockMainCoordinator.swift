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

import WireMainNavigationUI
import UIKit

final class MockMainCoordinatorProtocol: MainCoordinatorProtocol {
    typealias Dependencies = MockMainCoordinatorDependencies

    func showConversationList(conversationFilter: ConversationFilter?) async {
        <#code#>
    }
    
    func showArchive() async {
        <#code#>
    }
    
    func showSettings() async {
        <#code#>
    }
    
    func showConversation(conversation: ConversationModel, message: ConversationMessageModel?) async {
        <#code#>
    }
    
    func hideConversation() {
        <#code#>
    }
    
    func showSettingsContent(_ topLevelMenuItem: SettingsTopLevelMenuItem) {
        <#code#>
    }
    
    func hideSettingsContent() {
        <#code#>
    }
    
    func showSelfProfile() async {
        <#code#>
    }
    
    func showUserProfile(user: User) async {
        <#code#>
    }
    
    func showConnect() async {
        <#code#>
    }
    
    func showCreateGroupConversation() async {
        <#code#>
    }
    
    func presentViewController(_ viewController: UIViewController) async {
        <#code#>
    }
    
    func dismissPresentedViewController() async {
        <#code#>
    }
}
