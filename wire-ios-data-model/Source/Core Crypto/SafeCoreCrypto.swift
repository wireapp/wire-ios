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

    private let backgroundTaskManager: (any BackgroundTaskManager)?
    let coreCrypto: any CoreCryptoProtocol

    public init(
        backgroundTaskManager: (any BackgroundTaskManager)?,
        coreCrypto: any CoreCryptoProtocol
    ) {
        self.backgroundTaskManager = backgroundTaskManager
        self.coreCrypto = coreCrypto
    }

    public func registerEpochObserver(_ epochObserver: any EpochObserver) async throws {
        try await coreCrypto.registerEpochObserver(epochObserver)
    }

    public func transaction<Result>(
        block: @escaping (any CoreCryptoContextProtocol) async throws -> Result
    ) async throws -> Result {
        try await withBackgroundTask(
            name: "core crypto transaction",
            executer: PassthroughTaskExecuter()
        ) { [coreCrypto] in
            try await coreCrypto.transaction(block)
        }
    }

}
