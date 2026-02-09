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

/// A UserDefaults wrapper that uses prefixed keys with UserDefaults.standard
/// instead of suite-specific defaults to avoid iOS Simulator entitlements hang.
final class PrefixedUserDefaults: UserDefaults {
    private let keyPrefix: String
    private let trackedKeys = NSMutableSet()

    init(keyPrefix: String) {
        self.keyPrefix = keyPrefix
        super.init(suiteName: nil)!
    }

    private func prefixedKey(_ key: String) -> String {
        let prefixed = "\(keyPrefix)_\(key)"
        trackedKeys.add(prefixed)
        return prefixed
    }

    override func set(_ value: Any?, forKey defaultName: String) {
        UserDefaults.standard.set(value, forKey: prefixedKey(defaultName))
    }

    override func set(_ value: Int, forKey defaultName: String) {
        UserDefaults.standard.set(value, forKey: prefixedKey(defaultName))
    }

    override func set(_ value: Bool, forKey defaultName: String) {
        UserDefaults.standard.set(value, forKey: prefixedKey(defaultName))
    }

    override func object(forKey defaultName: String) -> Any? {
        UserDefaults.standard.object(forKey: prefixedKey(defaultName))
    }

    override func string(forKey defaultName: String) -> String? {
        UserDefaults.standard.string(forKey: prefixedKey(defaultName))
    }

    override func integer(forKey defaultName: String) -> Int {
        UserDefaults.standard.integer(forKey: prefixedKey(defaultName))
    }

    override func bool(forKey defaultName: String) -> Bool {
        UserDefaults.standard.bool(forKey: prefixedKey(defaultName))
    }

    func removeAllPrefixedKeys() {
        for key in trackedKeys.allObjects {
            if let key = key as? String {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
        trackedKeys.removeAllObjects()
    }
}

final class BackendInfoTestObserver: NSObject, XCTestObservation {

    private let keyPrefix = UUID().uuidString
    private let defaults: PrefixedUserDefaults
    private let apiVersion: APIVersion?
    private let preferredAPIVersion: APIVersion?
    private let domain: String?
    private let isFederationEnabled: Bool

    init(apiVersion: APIVersion?, preferredAPIVersion: APIVersion?, domain: String?, isFederationEnabled: Bool) {
        self.defaults = PrefixedUserDefaults(keyPrefix: keyPrefix)
        self.apiVersion = apiVersion
        self.preferredAPIVersion = preferredAPIVersion
        self.domain = domain
        self.isFederationEnabled = isFederationEnabled
    }

    func testCaseWillStart(_ testCase: XCTestCase) {
        BackendInfo.storage = defaults
        BackendInfo.apiVersion = apiVersion
        BackendInfo.preferredAPIVersion = preferredAPIVersion
        BackendInfo.domain = domain
        BackendInfo.isFederationEnabled = isFederationEnabled
    }

    func testCaseDidFinish(_ testCase: XCTestCase) {
        defaults.removeAllPrefixedKeys()
    }

}
