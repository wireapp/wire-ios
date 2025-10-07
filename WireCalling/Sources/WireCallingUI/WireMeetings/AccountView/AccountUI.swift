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
import WireAccountImageUI
import WireDesign

struct AccountUI: View {
    private let viewModel: AccountUIViewModel

    init(viewModel: AccountUIViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        let accountImageViewDesign = AccountImageViewDesign()
        let availabilityIndicatorDesign = accountImageViewDesign.availabilityIndicator
        HStack(spacing: 4) {
            AccountImageViewRepresentable(
                source: viewModel.avatarSource,
                availability: viewModel.availability,
                showNotificationsBadge: false
            )
            .accountImageBorderWidth(accountImageViewDesign.borderWidth)
            .accountImageViewBorderColor(accountImageViewDesign.borderColor)
            .availabilityIndicatorAvailableColor(availabilityIndicatorDesign.availableColor)
            .availabilityIndicatorAwayColor(availabilityIndicatorDesign.awayColor)
            .availabilityIndicatorBusyColor(availabilityIndicatorDesign.busyColor)
            .availabilityIndicatorBackgroundViewColor(availabilityIndicatorDesign.backgroundViewColor)
            .frame(width: 28, height: 28)
        }
        .fixedSize()
    }
}
