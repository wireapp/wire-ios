//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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
import WireLogging
import WireAuthenticationAPI

@MainActor
package final class AccountTypeSelectionViewModel: ObservableObject {

    @Published var isCreateTeamAccountPresented = false

    private let analyticsTracker: any AccountRegistrationAnalyticsTrackerProtocol

    private let teamsURL: URL

    lazy var teamAccountCreationLink: URL? = {
        guard var components = URLComponents(url: teamsURL, resolvingAgainstBaseURL: false) else {
            WireLogger.authentication
                .warn("Unable to generate team account creation link. Invalid teamsURL: \(teamsURL.absoluteString)")
            return nil
        }

        let appendedPath = components.path.appending("/register/email")
        components.path = appendedPath

        components.queryItems = (components.queryItems ?? []) + [
            URLQueryItem(name: "origin", value: "ios")
        ]

        return components.url
    }()

    init(
        teamsURL: URL,
        analyticsTracker: any AccountRegistrationAnalyticsTrackerProtocol
    ) {
        self.teamsURL = teamsURL
        self.analyticsTracker = analyticsTracker
    }

}
