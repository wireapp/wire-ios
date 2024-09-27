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

#if canImport(WireDatadog)

    import UIKit
    import WireDatadog
    import class WireTransport.BackendEnvironment

    struct WireDatadogBuilder {
        // MARK: Internal

        // MARK: - Build

        func build() -> WireDatadog {
            guard
                let applicationID = bundle.infoForKey(Constants.keyAppId),
                let buildNumber = mainBundle.infoForKey(Constants.keyBundleVersion),
                let buildVersion = mainBundle.infoForKey(Constants.keyBundleShortVersion),
                let clientToken = bundle.infoForKey(Constants.keyClientToken)
            else {
                preconditionFailure("Datadog is enabled, but the bundle misses required input.")
            }

            return WireDatadog(
                applicationID: applicationID,
                buildVersion: buildVersion,
                buildNumber: buildNumber,
                clientToken: clientToken,
                identifierForVendor: device.identifierForVendor,
                environmentName: environment.title
            )
        }

        // MARK: Private

        private enum Constants {
            static let keyAppId = "DatadogAppId"
            static let keyBundleVersion = "CFBundleVersion"
            static let keyBundleShortVersion = "CFBundleShortVersionString"
            static let keyClientToken = "DatadogClientToken"
        }

        private let device: UIDevice = .current
        private let environment: BackendEnvironment = .shared
        private let bundle: Bundle = .wireCommonComponents
        private let mainBundle: Bundle = .appMainBundle
    }

#endif
