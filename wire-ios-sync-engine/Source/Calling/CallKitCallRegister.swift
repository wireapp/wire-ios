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

import Foundation

class CallKitCallRegister {

    // MARK: - Properties

    // Keep each storage change and its publication in the same critical section.
    private let storageLock = NSLock()
    private var storage = [UUID: CallKitCall]()

    // MARK: - Life cycle

    init() {
        persistStorage()
    }

    deinit {
        persistStorage()
    }

    // MARK: - Persistence

    private func persistStorage() {
        VoIPPushHelper.knownCallHandles = storage.values.map(\.handle.encodedString)
    }

    // MARK: - Registration

    func registerNewCall(with handle: CallHandle) -> CallKitCall {
        let call = CallKitCall(id: UUID(), handle: handle)
        storageLock.withLock {
            storage[call.id] = call
            persistStorage()
        }
        return call
    }

    func unregisterCall(_ call: CallKitCall) {
        storageLock.withLock {
            storage.removeValue(forKey: call.id)
            persistStorage()
        }
    }

    func reset() {
        storageLock.withLock {
            storage.removeAll()
            persistStorage()
        }
    }

    // MARK: - Lookup

    var allCalls: [CallKitCall] {
        storageLock.withLock { Array(storage.values) }
    }

    func callExists(for id: UUID) -> Bool {
        lookupCall(by: id) != nil
    }

    func lookupCall(by id: UUID) -> CallKitCall? {
        storageLock.withLock { storage[id] }
    }

    func callExists(for handle: CallHandle) -> Bool {
        lookupCall(by: handle) != nil
    }

    func lookupCall(by handle: CallHandle) -> CallKitCall? {
        lookupCalls(by: handle).first
    }

    func lookupCalls(by handle: CallHandle) -> [CallKitCall] {
        storageLock.withLock { storage.values.filter { $0.handle == handle } }
    }

}
