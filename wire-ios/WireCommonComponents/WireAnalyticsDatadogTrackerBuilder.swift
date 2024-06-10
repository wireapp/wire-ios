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

#if canImport(WireDatadogTracker)

import CryptoKit
import UIKit
import WireDatadogTracker
import class WireTransport.BackendEnvironment

struct WireAnalyticsDatadogTrackerBuilder {

    private enum Constants {
        static let keyAppId = "DatadogAppId"
        static let keyClientToken = "DatadogClientToken"
    }

    private let environment: BackendEnvironment = .shared
    private let bundle: Bundle = .wireCommonComponents

    // MARK: - Build

    func build() -> WireAnalyticsTracker? {
        guard
            let appID = bundle.infoForKey(Constants.keyAppId),
            let clientToken = bundle.infoForKey(Constants.keyClientToken)
        else {
            return nil
        }

        return WireAnalyticsTracker(
            appID: appID,
            clientToken: clientToken,
            datadogUserID: datadogUserIdentifier(),
            environmentName: environmentName()
        )
    }

    // MARK: - Helpers

    private func datadogUserIdentifier() -> String {
        guard let identifier = UIDevice.current.identifierForVendor?.uuidString else {
            return "none"
        }

        let data = Data(identifier.utf8)

        return SHA256.hash(data: data)
            .compactMap { String(format: "%02x", $0) }
            .joined()
    }

    private func environmentName() -> String {
        environment.title.replacingOccurrences(
            of: "[^A-Za-z0-9]+",
            with: "",
            options: [.regularExpression]
        )
    }
}

#endif
