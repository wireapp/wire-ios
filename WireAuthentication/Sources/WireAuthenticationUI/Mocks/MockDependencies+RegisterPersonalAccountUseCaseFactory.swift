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
import WireAuthenticationAPI
import WireNetwork

extension MockDependencies: RegisterPersonalAccountUseCaseFactory {

    nonisolated
    func registerPersonalAccountUseCase() async throws -> any RegisterPersonalAccountUseCaseProtocol {
        MockRegisterPersonalAccountUseCase()
    }

    var analyticsEventTracker: RegistrationAnalyticsTrackerProtocol {
        MockRegistrationAnalyticsTracker()
    }

}

struct MockRegisterPersonalAccountUseCase: RegisterPersonalAccountUseCaseProtocol {

    func invoke(
        email: String,
        password: String,
        verificationCode: String,
        name: String
    ) async throws -> ([HTTPCookie], UUID?) {
        ([], UUID())
    }

}

private struct MockRegistrationAnalyticsTracker: RegistrationAnalyticsTrackerProtocol {

    var trackingID: String?

    func isAnalyticsTrackingAvailable(for environment: BackendEnvironment2) -> Bool { false }
    func setUp() {}
    func tearDown() {}
    func trackPersonalAccountCreationStart() {}
    func trackPersonalAccountCreationReachedTermsOfUseConfirmation() {}
    func trackPersonalAccountCreationReachedVerificationCode() {}
    func trackPersonalAccountCreationFailedCodeVerification() {}
    func trackPersonalAccountCreationReachedUsernameForm() {}
    func trackPersonalAccountCreationCompletion() {}
    func deleteTemporaryTrackingID() {}

}
