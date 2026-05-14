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

import UIKit

struct CallingActionsInfoViewModel {

    struct DisplayState {
        let isIncomingCall: Bool
        let isSecurityLevelVisible: Bool
    }

    struct LayoutState {
        let actionsHeight: CGFloat
        let stackViewAlignment: UIStackView.Alignment
    }

    func participantsHeaderTitle(count: Int) -> String {
        L10n.Localizable.Call.Participants.showAll(count).uppercased()
    }

    func displayState(for configuration: CallInfoConfiguration) -> DisplayState {
        DisplayState(
            isIncomingCall: configuration.state.isIncoming,
            isSecurityLevelVisible: configuration.classification != nil
        )
    }

    func layoutState(
        isLandscape: Bool,
        displayState: DisplayState,
        bottomSafeAreaInset: CGFloat
    ) -> LayoutState {
        LayoutState(
            actionsHeight: actionsHeight(
                isLandscape: isLandscape,
                isIncomingCall: displayState.isIncomingCall,
                isSecurityLevelVisible: displayState.isSecurityLevelVisible,
                bottomSafeAreaInset: bottomSafeAreaInset
            ),
            stackViewAlignment: stackViewAlignment(isLandscape: isLandscape)
        )
    }

    func actionsHeight(
        isLandscape: Bool,
        isIncomingCall: Bool,
        isSecurityLevelVisible: Bool,
        bottomSafeAreaInset: CGFloat
    ) -> CGFloat {
        var baseHeight: CGFloat = if isLandscape {
            128
        } else {
            isIncomingCall ? 250 : 128
        }

        if isSecurityLevelVisible {
            baseHeight += SecurityLevelView.securityLevelViewHeight
        }

        return baseHeight + bottomSafeAreaInset
    }

    func stackViewAlignment(isLandscape: Bool) -> UIStackView.Alignment {
        isLandscape ? .center : .fill
    }
}
