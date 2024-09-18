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

import Foundation
import WireFoundation

/// A class which serves as bridge between the `SidebarView` and the `SidebarViewController`.
/// It's injected into the `SidebarAdapter` where changes are observed while the hosting controller also keeps a reference.
final class SidebarModel: ObservableObject {

    @Published var wireTextStyleMapping: WireTextStyleMapping?
    @Published var accountInfo: SidebarAccountInfo
    @Published var conversationFilter: SidebarConversationFilter? {
        didSet { conversationFilterUpdated(conversationFilter) }
    }

    let accountImageAction: () -> Void
    let conversationFilterUpdated: (_ conversationFilter: SidebarConversationFilter?) -> Void
    let connectAction: () -> Void
    let settingsAction: () -> Void
    let supportAction: () -> Void

    init(
        accountInfo: SidebarAccountInfo,
        conversationFilter: SidebarConversationFilter?,
        accountImageAction: @escaping () -> Void,
        conversationFilterUpdated: @escaping (_ conversationFilter: SidebarConversationFilter?) -> Void,
        connectAction: @escaping () -> Void,
        settingsAction: @escaping () -> Void,
        supportAction: @escaping () -> Void
    ) {
        self.accountInfo = accountInfo
        self.conversationFilter = conversationFilter
        self.accountImageAction = accountImageAction
        self.conversationFilterUpdated = conversationFilterUpdated
        self.connectAction = connectAction
        self.settingsAction = settingsAction
        self.supportAction = supportAction
    }
}
