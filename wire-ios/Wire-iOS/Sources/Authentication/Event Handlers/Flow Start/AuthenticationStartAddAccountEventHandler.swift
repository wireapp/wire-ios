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

/// Handles requests to add a new user account.
final class AuthenticationStartAddAccountEventHandler: AuthenticationEventHandler {

    let featureProvider: AuthenticationFeatureProvider
    weak var statusProvider: AuthenticationStatusProvider?

    init(featureProvider: AuthenticationFeatureProvider) {
        self.featureProvider = featureProvider
    }

    func handleEvent(currentStep: AuthenticationFlowStep, context: (NSError?, Int)) -> [AuthenticationCoordinatorAction]? {
        if featureProvider.allowOnlyEmailLogin {
            // Hide the landing screen if account creation is disabled.
            return [.transition(.provideCredentials(nil), mode: .reset)]
        } else {
            return [.transition(.landingScreen, mode: .reset)]
        }
    }
}
