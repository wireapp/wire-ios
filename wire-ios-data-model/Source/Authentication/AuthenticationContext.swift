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
import LocalAuthentication

// MARK: - AuthenticationContextProtocol

// sourcery: AutoMockable
/// An abstraction around authentication via `LAContext`.
public protocol AuthenticationContextProtocol {
    var laContext: LAContext { get }
    var evaluatedPolicyDomainState: Data? { get }

    func canEvaluatePolicy(_ policy: LAPolicy, error: NSErrorPointer) -> Bool
    func evaluatePolicy(_ policy: LAPolicy, localizedReason: String, reply: @escaping (Bool, Error?) -> Void)
}

// MARK: - AuthenticationContext

public struct AuthenticationContext: AuthenticationContextProtocol {
    // MARK: Lifecycle

    public init(storage: any LAContextStorable) {
        self.storage = storage
    }

    // MARK: Public

    public var laContext: LAContext {
        storedContext()
    }

    public var evaluatedPolicyDomainState: Data? {
        storedContext().evaluatedPolicyDomainState
    }

    public func canEvaluatePolicy(_ policy: LAPolicy, error: NSErrorPointer) -> Bool {
        storedContext().canEvaluatePolicy(policy, error: error)
    }

    public func evaluatePolicy(
        _ policy: LAPolicy,
        localizedReason: String,
        reply: @escaping (Bool, (any Error)?) -> Void
    ) {
        WireLogger.ear.info("AuthenticationContext: evaluatePolicy")
        storedContext().evaluatePolicy(policy, localizedReason: localizedReason, reply: reply)
    }

    // MARK: Private

    private let storage: any LAContextStorable

    // MARK: Helpers

    private func storedContext() -> LAContext {
        if let context = storage.context {
            return context
        } else {
            let context = LAContext()
            storage.context = context
            return context
        }
    }
}
