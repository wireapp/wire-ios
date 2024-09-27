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

import WireTransport
import XCTest

public func makeBackendInfoTestObserver(
    apiVersion: APIVersion?,
    preferredAPIVersion: APIVersion?,
    domain: String?,
    isFederationEnabled: Bool
) -> XCTestObservation {
    BackendInfoTestObserver(
        apiVersion: apiVersion,
        preferredAPIVersion: preferredAPIVersion,
        domain: domain,
        isFederationEnabled: isFederationEnabled
    )
}

// MARK: - BackendInfoTestObserver

final class BackendInfoTestObserver: NSObject, XCTestObservation {
    // MARK: Lifecycle

    init(apiVersion: APIVersion?, preferredAPIVersion: APIVersion?, domain: String?, isFederationEnabled: Bool) {
        self.defaults = UserDefaults(suiteName: suiteName)!
        self.apiVersion = apiVersion
        self.preferredAPIVersion = preferredAPIVersion
        self.domain = domain
        self.isFederationEnabled = isFederationEnabled
    }

    // MARK: Internal

    func testCaseWillStart(_: XCTestCase) {
        BackendInfo.storage = defaults
        BackendInfo.apiVersion = apiVersion
        BackendInfo.preferredAPIVersion = preferredAPIVersion
        BackendInfo.domain = domain
        BackendInfo.isFederationEnabled = isFederationEnabled
    }

    func testCaseDidFinish(_: XCTestCase) {
        defaults.removePersistentDomain(forName: suiteName)
    }

    // MARK: Private

    private let suiteName = UUID().uuidString
    private let defaults: UserDefaults
    private let apiVersion: APIVersion?
    private let preferredAPIVersion: APIVersion?
    private let domain: String?
    private let isFederationEnabled: Bool
}
