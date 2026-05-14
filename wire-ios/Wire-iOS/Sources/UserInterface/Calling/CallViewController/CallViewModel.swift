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

import Foundation
import WireSyncEngine

struct CallViewModel {

    enum OverlayStateAction {
        case startTimer
        case stopTimer
        case showOverlayAndStopTimer
        case none
    }

    func canHideOverlay(
        callState: CallStatusViewState,
        shouldOverlayStayVisibleForAutomation: Bool
    ) -> Bool {
        guard case .established = callState else { return false }
        return !shouldOverlayStayVisibleForAutomation
    }

    func overlayStateAction(
        canHideOverlay: Bool,
        isOverlayVisible: Bool,
        hasOverlayTimer: Bool
    ) -> OverlayStateAction {
        if canHideOverlay {
            return hasOverlayTimer ? .none : .startTimer
        }

        return isOverlayVisible ? .stopTimer : .showOverlayAndStopTimer
    }

    func shouldHideOverlayAfterCallEstablished(
        hasOverlayTimer: Bool,
        canHideOverlay: Bool,
        isOverlayVisible: Bool,
        isAnimating: Bool
    ) -> Bool {
        !hasOverlayTimer && canHideOverlay && isOverlayVisible && !isAnimating
    }

    func shouldRestartOverlayTimer(
        hasOverlayTimer: Bool,
        canHideOverlay: Bool
    ) -> Bool {
        hasOverlayTimer && canHideOverlay
    }

    func preferredVideoPlaceholderState(for newVideoState: VideoState) -> CallVideoPlaceholderState {
        newVideoState == .stopped ? .statusTextHidden : .hidden
    }

    func shouldDisableVideo(permissions: CallPermissionsConfiguration) -> Bool {
        permissions.isVideoDisabledForever
    }

    func nextCameraType(currentCameraType: CaptureDevice) -> CaptureDevice {
        currentCameraType == .front ? .back : .front
    }
}
