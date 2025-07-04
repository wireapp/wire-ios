//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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
import WireDomain
import WireLogging

/// Issue: some users had conversations in their database that weren't fully up do date with the backend.
/// Fix: re-sync all conversations.

struct AppVersionMigration_4_1_0: AppVersionMigration {

    let version: SemanticVersion = "4.1.0"
    private let pullAllConversationsSync: any PullAllConversationsSyncProtocol

    init(
        pullAllConversationsSync: any PullAllConversationsSyncProtocol
    ) {
        self.pullAllConversationsSync = pullAllConversationsSync
    }

    func perform() async throws {

        try await pullAllConversationsSync.pull()
    }
}
