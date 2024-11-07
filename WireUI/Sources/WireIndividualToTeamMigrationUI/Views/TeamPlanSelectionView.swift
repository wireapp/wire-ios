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

struct TeamPlanSelectionView: View {

    enum Action {
        case goToPlans
        case goBack
        case `continue`
    }

    let features: [TeamPlanFeature]

    var body: some View {
        VStack(alignment: .leading) {
            Text(String.localized(key: "individualToTeam.planSelection.body", bundle: .module))
                .wireTextStyle(.body1)
            Spacer()
                .frame(height: 24)
            VStack(alignment: .leading) {
                ForEach(features) { feature in
                    FeatureDescriptionComponent(feature: feature)
                        .padding(.top, 16)
                        .padding(.bottom, 12)
                    if feature != features.last {
                        Divider()
                    }
                }
            }
            // TODO: Add a "link" Text Style?
            Button(
                action: { },
                label: {
                    Text(String.localized(key: "individualToTeam.planSelection.url", bundle: .module))
                        .tint(.primary)
                        .underline()
                }
            )
            .padding(.top, 4)
            Spacer()
            CallToActionButton(
                title: String.localized(key: "individualToTeam.button.continue", bundle: .module),
                action: { }
            )
        }
    }
}
