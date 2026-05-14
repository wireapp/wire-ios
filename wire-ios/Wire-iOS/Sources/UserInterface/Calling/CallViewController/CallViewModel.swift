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

    enum CallActionPlan {
        case continueDegradedCall
        case acceptCall
        case acceptDegradedCall
        case terminateCall
        case terminateDegradedCall
        case toggleMuteState
        case toggleSpeakerState
        case minimizeOverlay
        case toggleVideoState
        case alertVideoUnavailable
        case flipCamera
        case showParticipantsList
        case updateVideoGridPresentationMode(VideoGridPresentationMode)
    }

    enum ContextAction {
        case startOverlayTimer
        case stopOverlayTimer
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

    func plan(for action: CallAction) -> CallActionPlan {
        switch action {
        case .continueDegradedCall:
            .continueDegradedCall
        case .acceptCall:
            .acceptCall
        case .acceptDegradedCall:
            .acceptDegradedCall
        case .terminateCall:
            .terminateCall
        case .terminateDegradedCall:
            .terminateDegradedCall
        case .toggleMuteState:
            .toggleMuteState
        case .toggleSpeakerState:
            .toggleSpeakerState
        case .minimizeOverlay:
            .minimizeOverlay
        case .toggleVideoState:
            .toggleVideoState
        case .alertVideoUnavailable:
            .alertVideoUnavailable
        case .flipCamera:
            .flipCamera
        case .showParticipantsList:
            .showParticipantsList
        case let .updateVideoGridPresentationMode(mode):
            .updateVideoGridPresentationMode(mode)
        }
    }

    func contextAction(
        for context: CallInfoRootViewController.Context,
        canHideOverlay: Bool
    ) -> ContextAction {
        guard canHideOverlay else { return .none }

        switch context {
        case .overview:
            return .startOverlayTimer
        case .participants:
            return .stopOverlayTimer
        }
    }
}
