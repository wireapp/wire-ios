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

import SwiftUI
import WireDesign
import WireFoundation

@MainActor
@ViewBuilder
func teamPlanSelectionPreview() -> some View {
    let features: [TeamPlanFeature] = [
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
            description: .localizedMarkdown(
                key: "individualToTeam.planSelection.feature.meetings",
                bundle: .module
            )
        ),
        .init(
            id: "status",
            description: .localizedMarkdown(
                key: "individualToTeam.planSelection.feature.status",
                bundle: .module
            )
        ),
        .init(
            id: "enterprise",
            description: .localizedMarkdown(
                key: "individualToTeam.planSelection.feature.enterprise",
                bundle: .module
            )
        )
    ]

    PageContainer(
        content: {
            TeamPlanSelectionView(
                features: features
            ) { _ in }
        },
        step: 1,
        stepCount: 4,
        stepTitle: String.localized(key: "individualToTeam.planSelection.title", bundle: .module)
    )
    .environment(\.wireTextStyleMapping, WireTextStyleMapping())

}
