//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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
import WireLogging

public typealias Reachability = ReachabilityProvider & TearDownCapable

extension BackendEnvironmentProvider {

    func reachabilityWrapper(enabled: Bool = false) -> ReachabilityWrapper {
        ReachabilityWrapper(enabled: enabled, reachabilityClosure: {
            self.reachability
        })
    }
}

// MARK: - ReachabilityWrapper

/// Wrapper around Reachability to delay network calls if needed
final class ReachabilityWrapper: NSObject, ReachabilityProvider, TearDownCapable {

    var mayBeReachable: Bool {
        safeReachability?.mayBeReachable == true
    }

    var oldMayBeReachable: Bool {
        safeReachability?.oldMayBeReachable == true
    }

    func add(_ observer: ZMReachabilityObserver, queue: OperationQueue?) -> Any {
        guard let reachability = safeReachability, enabled else {
            return NSObject()
        }
        return reachability.add(observer, queue: queue)
    }

    func addReachabilityObserver(on queue: OperationQueue?, block: @escaping ReachabilityObserverBlock) -> Any {
        guard let reachability = safeReachability, enabled else {
            return NSObject()
        }

        return reachability.addReachabilityObserver(on: queue, block: block)
    }

    var enabled: Bool {
        didSet {
            WireLogger.backend.debug("did set reachability enabled: \(enabled)")
            if safeReachability == nil, enabled {
                safeReachability = reachabilityClosure()
                NotificationCenter.default.post(
                    name: NSNotification.Name(rawValue: ZMTransportSessionReachabilityIsEnabled),
                    object: self
                )
            } else if !enabled {
                safeReachability?.tearDown()
                safeReachability = nil
            }
        }
    }

    var reachabilityClosure: () -> Reachability
    private var safeReachability: Reachability? {
        didSet {
            if safeReachability == nil {
                WireLogger.backend.debug("did clear reachability provider")
            } else {
                WireLogger.backend.debug("did set reachability provider")
            }
        }
    }

    init(enabled: Bool, reachabilityClosure: @escaping () -> Reachability) {
        self.enabled = enabled
        self.reachabilityClosure = reachabilityClosure
        super.init()
        if enabled {
            self.safeReachability = reachabilityClosure()
        }
    }

    func tearDown() {
        safeReachability?.tearDown()
    }
}
