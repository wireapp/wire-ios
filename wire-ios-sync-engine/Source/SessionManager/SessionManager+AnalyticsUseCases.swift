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

    enum SessionManagerError: Error {

        case missingAnalyticsManager
        case missingAnalyticsUserProfile
        case missingActiveUserSession

    }

    public func makeDisableAnalyticsSharingUseCase() throws -> DisableAnalyticsSharingUseCaseProtocol {
        guard let analyticsManager = analyticsManager else {
            throw SessionManagerError.missingAnalyticsManager
        }
        return DisableAnalyticsSharingUseCase(analyticsManager: analyticsManager)
    }

    public func makeEnableAnalyticsSharingUseCase() throws -> EnableAnalyticsSharingUseCaseProtocol {
        guard let analyticsManager = analyticsManager else {
            throw SessionManagerError.missingAnalyticsManager
        }

        guard let analyticsUserProfile = getUserAnalyticsProfileForActiveUserSession() else {
            throw SessionManagerError.missingAnalyticsUserProfile
        }

        guard let useSession = self.activeUserSession else {
            throw SessionManagerError.missingActiveUserSession
        }

        return EnableAnalyticsSharingUseCase(
            analyticsManager: analyticsManager,
            analyticsUserProfile: analyticsUserProfile,
            userSession: useSession
        )
    }

}
