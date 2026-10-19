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

/// Something an epoch observer can be registered with, i.e. a `CoreCrypto` instance.
protocol EpochObserverRegistrar {

    func registerEpochObserver(epochObserver: any EpochObserver) async throws

}

extension CoreCrypto: EpochObserverRegistrar {}

/// Decides when the epoch observer can be registered.
///
/// Core Crypto can only observe epochs once MLS has been initialised, so the observer is only
/// registered once both an observer is provided and MLS is initialised, in whichever order that
/// happens, and at most once.
///
/// Not thread safe, it's meant to be owned and used by a single actor.
final class EpochObserverRegistration {

    private var observer: (any EpochObserver)?
    private var isMLSInitialised = false
    private var hasRegistered = false

    func setObserver(_ observer: any EpochObserver) {
        self.observer = observer
    }

    func markMLSInitialised() {
        isMLSInitialised = true
    }

    /// Registers the observer with `registrar` if it's ready to be and hasn't been yet.
    func registerIfNecessary(with registrar: some EpochObserverRegistrar) async throws {
        guard let observer, isMLSInitialised, !hasRegistered else {
            return
        }

        // Set before suspending so a concurrent call can't register a second time.
        hasRegistered = true
        do {
            try await registrar.registerEpochObserver(epochObserver: observer)
        } catch {
            hasRegistered = false
            throw error
        }
    }

}
