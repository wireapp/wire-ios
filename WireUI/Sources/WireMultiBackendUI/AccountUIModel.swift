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

import Foundation
import WireAccountImageUI

public struct AccountUIModel: Identifiable {

    public let id = UUID()

    let avatarSource: AccountImageSource
    let name: String
    let handle: String?
    let teamName: String?
    let backendName: String?
    let action: () -> Void

    public init(
        avatarSource: AccountImageSource,
        name: String,
        handle: String?,
        teamName: String?,
        backendName: String?,
        action: @escaping () -> Void
    ) {
        self.avatarSource = avatarSource
        self.name = name
        self.handle = handle
        self.teamName = teamName
        self.backendName = backendName
        self.action = action
    }
}
