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

@objc(ZMSDispatchGroup) @objcMembers
public final class ZMSDispatchGroup: NSObject {

    let label: String

    private let group: DispatchGroup

    public convenience init(label: String) {
        self.init(dispatchGroup: .init(), label: label)
    }

    public init(dispatchGroup group: DispatchGroup, label: String) {
        self.group = group
        self.label = label
    }

    public func enter() {
        group.enter()
    }

    public func leave() {
        group.leave()
    }

    @objc(notifyOnQueue:block:)
    public func notify(on queue: DispatchQueue, block: @escaping () -> Void) {
        group.notify(queue: queue, execute: block)
    }

    @discardableResult
    public func wait(withTimeout timeout: DispatchTime) -> Int {
        let result = group.wait(timeout: timeout)
        return result == .success ? 0 : 1
    }

    @discardableResult @objc(waitWithDeltaFromNow:)
    public func wait(deltaFromNow nanoseconds: Int) -> Int {
        wait(withTimeout: .now() + .nanoseconds(nanoseconds))
    }

    @discardableResult
    public func waitWithTimeoutForever() -> Int {
        wait(withTimeout: .distantFuture)
    }

    @discardableResult
    public func wait(forInterval timeout: TimeInterval) -> Int {
        let nanoseconds = Int(timeout * 1_000_000_000)
        return wait(deltaFromNow: nanoseconds)
    }

    @objc(asyncOnQueue:block:)
    public func async(on queue: dispatch_queue_t, block: @escaping () -> Void) {
        queue.async(group: group, execute: block)
    }
}
