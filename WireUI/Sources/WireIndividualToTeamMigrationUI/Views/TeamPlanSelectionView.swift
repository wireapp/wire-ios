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
import WireLocators

struct TeamPlanSelectionView: View {

    enum Action: Sendable {
        case goToPlans
        case `continue`
    }

    let actionCallback: (Action) -> Void
    let features: [TeamPlanFeature]

    init(features: [TeamPlanFeature], actionCallback: @escaping (Action) -> Void) {
        self.actionCallback = actionCallback
        self.features = features
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text(String.localized(key: "individualToTeam.planSelection.body", bundle: .module))
                .font(for: .body1)
            Spacer()
                .frame(height: 24)
            VStack(alignment: .leading) {
                ForEach(features) { feature in
                    FeatureDescriptionComponent(feature: feature)
                        .padding(.top, 12)
                        .padding(.bottom, 8)
                    if feature != features.last {
                        Divider()
                            .background(.primary)
                    }
                }
            }
            Button(
                action: {
                    actionCallback(.goToPlans)
                },
                label: {
                    Text(String.localized(key: "individualToTeam.planSelection.url", bundle: .module))
                        .lineLimit(nil)
                }
            )
            .wireButtonStyle(.link)
            .padding(.top, 4)
            Spacer()
            Button(
                action: { actionCallback(.continue) },
                label: { Text(String.localized(key: "individualToTeam.button.continue", bundle: .module)) }
            )
            .accessibilityIdentifier(Locators.TeamSetupStepsPage.continueButton.rawValue)
            .wireButtonStyle(.primary)
        }
    }
}

#Preview {
    teamPlanSelectionPreview()
}
