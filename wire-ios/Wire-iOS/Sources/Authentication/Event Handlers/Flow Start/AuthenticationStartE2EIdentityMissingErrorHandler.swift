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

/// Handles client registration errors related to the lack of a e2e identity enrollment on launch

final class AuthenticationStartE2EIdentityMissingErrorHandler: AuthenticationEventHandler {
    weak var statusProvider: AuthenticationStatusProvider?

    func handleEvent(
        currentStep: AuthenticationFlowStep,
        context: (NSError?, Int)
    ) -> [AuthenticationCoordinatorAction]? {
        let (error, _) = context

        // Only handle errors on start
        guard case .start = currentStep else {
            return nil
        }

        // Only handle needsToHandleToRegisterClient errors
        guard error?.userSessionErrorCode == .needsToEnrollE2EIToRegisterClient else {
            return nil
        }

        // Verify the state
        guard statusProvider?.selfUser != nil, statusProvider?.selfUserProfile != nil else {
            return nil
        }

        return [.startPostLoginFlow, .transition(.enrollE2EIdentity, mode: .reset)]
    }
}
