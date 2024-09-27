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

class CallKitCallRegister {
    // MARK: Lifecycle

    init() {
        persistStorage()
    }

    deinit {
        persistStorage()
    }

    // MARK: Internal

    // MARK: - Lookup

    var allCalls: [CallKitCall] {
        Array(storage.values)
    }

    // MARK: - Registration

    func registerNewCall(with handle: CallHandle) -> CallKitCall {
        defer { persistStorage() }
        let call = CallKitCall(id: UUID(), handle: handle)
        storage[call.id] = call
        return call
    }

    func unregisterCall(_ call: CallKitCall) {
        defer { persistStorage() }
        storage.removeValue(forKey: call.id)
    }

    func reset() {
        defer { persistStorage() }
        storage.removeAll()
    }

    func callExists(for id: UUID) -> Bool {
        lookupCall(by: id) != nil
    }

    func lookupCall(by id: UUID) -> CallKitCall? {
        storage[id]
    }

    func callExists(for handle: CallHandle) -> Bool {
        lookupCall(by: handle) != nil
    }

    func lookupCall(by handle: CallHandle) -> CallKitCall? {
        lookupCalls(by: handle).first
    }

    func lookupCalls(by handle: CallHandle) -> [CallKitCall] {
        storage.values.filter { $0.handle == handle }
    }

    // MARK: Private

    // MARK: - Properties

    private var storage = [UUID: CallKitCall]()

    // MARK: - Persistence

    private func persistStorage() {
        VoIPPushHelper.knownCallHandles = storage.values.map(\.handle.encodedString)
    }
}
