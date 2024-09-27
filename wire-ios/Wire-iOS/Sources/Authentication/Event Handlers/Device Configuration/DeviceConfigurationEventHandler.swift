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

import Foundation

final class DeviceConfigurationEventHandler: AuthenticationEventHandler {
    weak var statusProvider: AuthenticationStatusProvider?

    func handleEvent(currentStep: AuthenticationFlowStep, context: Void) -> [AuthenticationCoordinatorAction]? {
        // We normally expect the current step to be `configureDevice`, but in some cases
        // it also happens to be `deleteClient` so we handle in this case as well.
        switch currentStep {
        case .configureDevice,
             .deleteClient:
            if statusProvider?.sharedUserSession?.hasCompletedInitialSync == true {
                [.hideLoadingView, .completeLoginFlow]
            } else {
                [.transition(.pendingInitialSync, mode: .normal)]
            }

        default:
            nil
        }
    }
}
