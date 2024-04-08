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

public protocol AuthenticationContextProtocol {
    func canEvaluatePolicy(_ policy: LAPolicy) async throws -> Bool
    func evaluatePolicy(_ policy: LAPolicy, localizedReason: String) async throws -> Bool
    func evaluatedPolicyDomainState() async -> Data?
}

struct AuthenticationContext: AuthenticationContextProtocol {

    var evaluatedPolicyDomainState: Data?

    private let storage: LAContextStorable

    init(storage: LAContextStorable = LAContextStorage.shared) {
        self.storage = storage
    }

    func canEvaluatePolicy(_ policy: LAPolicy) async throws -> Bool {
        var error: NSError?
        let success = await storedContext().canEvaluatePolicy(policy, error: &error)

        if let error {
            throw AuthenticationContextError.underlyingLAError(error)
        }

        return success
    }

    func evaluatePolicy(_ policy: LAPolicy, localizedReason: String) async throws -> Bool {
        try await storedContext().evaluatePolicy(policy, localizedReason: localizedReason)
    }

    func evaluatedPolicyDomainState() async -> Data? {
        await storedContext().evaluatedPolicyDomainState
    }

    // MARK: Helpers

    private func storedContext() async -> LAContext {
        if let context = await storage.context {
            return context
        } else {
            let context = LAContext()
            await storage.setContext(context)
            return context
        }
    }
}
