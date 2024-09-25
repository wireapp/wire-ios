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

extension SessionManager {

    enum AnalyticsSessionError: Error {

        case analyticsNotAvailable
        case missingAnalyticsUserProfile
        case missingActiveUserSession

    }

    public func makeDisableAnalyticsUseCase() throws -> DisableAnalyticsUseCaseProtocol {
        guard let analyticsManager else {
            throw AnalyticsSessionError.analyticsNotAvailable
        }
        return DisableAnalyticsUseCase(analyticsManager: analyticsManager)
    }

    public func makeEnableAnalyticsUseCase() throws -> EnableAnalyticsUseCaseProtocol {
        guard let analyticsManager else {
            throw AnalyticsSessionError.analyticsNotAvailable
        }

        guard let userSession = self.activeUserSession else {
            throw AnalyticsSessionError.missingActiveUserSession
        }

        guard let analyticsUserProfile = getUserAnalyticsProfile(for: userSession) else {
            throw AnalyticsSessionError.missingAnalyticsUserProfile
        }

        return EnableAnalyticsUseCase(
            analyticsManager: analyticsManager,
            analyticsUserProfile: analyticsUserProfile,
            userSession: userSession
        )
    }

}
