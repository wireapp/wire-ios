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

struct CallingBottomSheetViewModel {

    struct ContentInteractionState: Equatable {
        let accessibilityElementsHidden: Bool
        let isUserInteractionEnabled: Bool
    }

    struct ConfigurationUpdateState: Equatable {
        let shouldUpdateHeaderBar: Bool
        let shouldReloadGrid: Bool
        let timerAction: CallStatusViewModel.TimerAction
        let isPanGestureEnabled: Bool
    }

    func bottomSheetHeight(
        availableHeight: CGFloat,
        headerHeight: CGFloat,
        defaultMaxHeight: CGFloat,
        isLandscape: Bool
    ) -> CGFloat {
        isLandscape ? availableHeight - headerHeight : defaultMaxHeight
    }

    func contentInteractionState(for bottomSheetState: BottomSheetContainerViewController.BottomSheetState)
        -> ContentInteractionState {
        switch bottomSheetState {
        case .initial:
            ContentInteractionState(accessibilityElementsHidden: false, isUserInteractionEnabled: true)
        case .full:
            ContentInteractionState(accessibilityElementsHidden: true, isUserInteractionEnabled: false)
        }
    }

    func configurationUpdateState(
        newConfiguration: CallInfoConfiguration,
        previousConfiguration: CallInfoConfiguration?
    ) -> ConfigurationUpdateState {
        let didCallStateChange = newConfiguration.state != previousConfiguration?.state
        let timerAction: CallStatusViewModel.TimerAction

        if didCallStateChange {
            timerAction = CallStatusViewModel().timerAction(for: newConfiguration.state)
        } else {
            timerAction = .keepCurrent
        }

        return ConfigurationUpdateState(
            shouldUpdateHeaderBar: didCallStateChange && newConfiguration.state.isEstablished,
            shouldReloadGrid: didCallStateChange,
            timerAction: timerAction,
            isPanGestureEnabled: !newConfiguration.state.isIncoming
        )
    }
}

private extension CallStatusViewState {
    var isEstablished: Bool {
        guard case .established = self else { return false }
        return true
    }
}
