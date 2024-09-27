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
import WireRequestStrategy
import WireTransport

private let log = ZMSLog(tag: "Network")

// MARK: - UnauthenticatedOperationLoop

class UnauthenticatedOperationLoop: NSObject {
    // MARK: Lifecycle

    init(
        transportSession: UnauthenticatedTransportSessionProtocol,
        operationQueue: GroupQueue,
        requestStrategies: [RequestStrategy]
    ) {
        self.transportSession = transportSession
        self.requestStrategies = requestStrategies
        self.operationQueue = operationQueue
        super.init()
        RequestAvailableNotification.addObserver(self)
    }

    deinit {
        precondition(tornDown, "Need to call tearDown before deinit")
    }

    // MARK: Internal

    let transportSession: UnauthenticatedTransportSessionProtocol
    let requestStrategies: [RequestStrategy]
    weak var operationQueue: GroupQueue?

    // MARK: Fileprivate

    fileprivate var tornDown = false
    fileprivate var shouldEnqueue = true
}

// MARK: TearDownCapable

extension UnauthenticatedOperationLoop: TearDownCapable {
    func tearDown() {
        shouldEnqueue = false
        requestStrategies.forEach { ($0 as? TearDownCapable)?.tearDown() }
        transportSession.tearDown()
        tornDown = true
    }
}

// MARK: RequestAvailableObserver

extension UnauthenticatedOperationLoop: RequestAvailableObserver {
    func newRequestsAvailable() {
        var enqueueMore = true
        while enqueueMore, shouldEnqueue {
            let result = transportSession.enqueueRequest(withGenerator: generator)
            enqueueMore = result == .success
            switch result {
            case .maximumNumberOfRequests: log.debug("Maximum number of concurrent requests reached")
            case .nilRequest: log.debug("Nil request generated")
            default: break
            }
        }
    }

    private var generator: ZMTransportRequestGenerator {
        { [weak self] in
            guard let self else {
                return nil
            }
            guard let apiVersion = BackendInfo.apiVersion else {
                return nil
            }
            let request = (requestStrategies as NSArray).nextRequest(for: apiVersion)
            guard let queue = operationQueue else {
                return nil
            }
            request?.add(ZMCompletionHandler(on: queue) { [weak self] _ in
                self?.newRequestsAvailable()
            })
            return request
        }
    }
}
