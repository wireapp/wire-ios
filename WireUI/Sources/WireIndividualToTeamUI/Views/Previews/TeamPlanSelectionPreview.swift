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

import SwiftUI

#Preview {
    WireIndividualToTeamMigrationContainerView(
        content: {
            TeamPleanSelectionView(
                features: [
                    .init(
                        id: "console",
                        description: "**Admin Console**: Invite team members and manage settings."
                    ),
                    .init(
                        id: "collaboration",
                        description: "**Effortless Collaboration**: Communicate with guests and external parties."
                    ),
                    .init(
                        id: "meetings",
                        description: "**Larger Meetings**: Join video conferences up to 150 participants."
                    ),
                    .init(
                        id: "status",
                        description: "**Availability Status**: Let your team know if you’re available, busy or away."
                    ),
                    .init(
                        id: "enterprise",
                        description: "**Upgrade to Enterprise**: Get additional features and premium support."
                    )
                ].compactMap { $0 },
                plansURL: URL(string: "https://wire.com/en/pricing")!
            )
        },
        step: 1,
        stepCount: 4,
        stepTitle: "Team Plan"
    )
}
