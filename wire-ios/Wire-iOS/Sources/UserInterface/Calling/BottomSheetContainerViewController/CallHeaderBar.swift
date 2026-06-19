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
import WireDesign
import WireLocators

struct CallHeaderState: Equatable {
    var title: String = ""
    var statusString: String = ""
    var shouldShowBitrateLabel: Bool = false
    var isConstantBitRate: Bool = false
}

struct CallHeaderBar: View {

    let state: CallHeaderState
    let onMinimize: () -> Void

    var body: some View {
        ZStack(alignment: .leading) {
            VStack(spacing: 0) {
                Text(state.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(uiColor: SemanticColors.Label.textDefault))
                    .accessibilityAddTraits(.isHeader)

                Text(state.statusString)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(Color(uiColor: SemanticColors.Label.textDefault))
                    .accessibilityIdentifier(Locators.OngoingCallPage.timeLabel.rawValue)

                if state.shouldShowBitrateLabel, BitRateStatus(state.isConstantBitRate) == .constant {
                    Text(L10n.Localizable.Call.Status.constantBitrate)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(Color(uiColor: SemanticColors.Label.textCollectionSecondary))
                        .accessibilityIdentifier("bitrate-indicator")
                        .accessibilityValue(BitRateStatus.constant.rawValue)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 32)

            Button(action: onMinimize) {
                Image(systemName: "chevron.down")
                    .foregroundColor(Color(uiColor: SemanticColors.View.backgroundDefaultBlack))
            }
            .frame(width: 32, height: 32)
            .padding(.leading, 20)
            .accessibilityLabel(L10n.Accessibility.Calling.HeaderBar.description)
        }
        .padding(.top, 10)
        .padding(.bottom, 6)
        .background(Color(uiColor: SemanticColors.View.backgroundDefault))
    }
}
