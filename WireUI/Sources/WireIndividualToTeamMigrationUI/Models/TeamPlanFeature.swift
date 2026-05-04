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

import SwiftUI

public struct TeamPlanFeature: Hashable, Identifiable, Sendable {
    public let id: String
    let description: AttributedString

    public init(id: String, description: AttributedString) {
        self.id = id
        self.description = description
    }
}

extension [TeamPlanFeature] {
    static var features: [TeamPlanFeature] {
        [
            .init(
                id: "console",
                description: .localizedMarkdown(
                    key: "individualToTeam.planSelection.feature.adminConsole",
                    bundle: .module
                )
            ),
            .init(
                id: "collaboration",
                description: .localizedMarkdown(
                    key: "individualToTeam.planSelection.feature.collaboration",
                    bundle: .module
                )
            ),
            .init(
                id: "meetings",
                description: .localizedMarkdown(key: "individualToTeam.planSelection.feature.meetings", bundle: .module)
            ),
            .init(
                id: "status",
                description: .localizedMarkdown(key: "individualToTeam.planSelection.feature.status", bundle: .module)
            ),
            .init(
                id: "enterprise",
                description: .localizedMarkdown(
                    key: "individualToTeam.planSelection.feature.enterprise",
                    bundle: .module
                )
            )
        ]
    }
}
