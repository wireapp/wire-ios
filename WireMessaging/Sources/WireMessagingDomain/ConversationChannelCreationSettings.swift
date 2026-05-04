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

public struct ConversationChannelCreationSettings: Equatable, Hashable {
    public let channelName: String
    public let channelAccess: ConversationChannelAccess
    public let appsAllowed: Bool
    public let guestsAllowed: Bool
    public let readReceiptsEnabled: Bool
    public let historyDepth: String?
    public let fileManagementEnabled: Bool

    package init(
        channelName: String,
        channelAccess: ConversationChannelAccess,
        appsAllowed: Bool,
        guestsAllowed: Bool,
        readReceiptsEnabled: Bool,
        historyDepth: String?,
        fileManagementEnabled: Bool
    ) {
        self.channelName = channelName
            .trimmingCharacters(in: .whitespacesAndNewlines)
        self.channelAccess = channelAccess
        self.appsAllowed = appsAllowed
        self.guestsAllowed = guestsAllowed
        self.readReceiptsEnabled = readReceiptsEnabled
        self.historyDepth = historyDepth
        self.fileManagementEnabled = fileManagementEnabled
    }
}
