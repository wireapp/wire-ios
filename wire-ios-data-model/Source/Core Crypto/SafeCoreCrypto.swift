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

import WireCoreCrypto
import WireLogging

/// A wrapper object for CoreCrypto that ensures transactions are executed
/// within a background task (if a task manager is provided).
public final class SafeCoreCrypto {

    let coreCrypto: any CoreCryptoProtocol

    public init(coreCrypto: any CoreCryptoProtocol) {
        self.coreCrypto = coreCrypto
    }

    public func registerEpochObserver(_ epochObserver: any EpochObserver) async throws {
        try await coreCrypto.registerEpochObserver(epochObserver)
    }

    /// Perform a transaction within an expiring activity to ensure the
    /// transaction has additional time to complete while the app transitions
    /// to a suspended state.
    ///
    /// This is particularly important when running in the main app because
    /// if the app is suspended during a transaction, then core crypto will
    /// hold on to a file lock used to coordinate cross-process concurrency
    /// and effectively block app extensions from being able to start their
    /// own transactions. This can lead to the Notification Service Extension
    /// being blocked and not process any notifications until the main app
    /// is resumed and the transaction is completed and the file lock released.
    ///
    public func transaction<Result>(
        block: @escaping @Sendable (any CoreCryptoContextProtocol) async throws -> Result
    ) async throws -> Result {
        try await withExpiringActivity(reason: "core crypto transaction") { [coreCrypto] in
            try await coreCrypto.transaction(block)
        }
    }

}
