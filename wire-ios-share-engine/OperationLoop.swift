//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
import CoreData
import ZMTransport


final class OperationLoop {

    typealias ChangeClosure = () -> Void

    private let context: NSManagedObjectContext
    public var changeClosure: ChangeClosure?
    private let callBackQueue: OperationQueue

    private var token: NSObjectProtocol? = nil

    init(context: NSManagedObjectContext, callBackQueue: OperationQueue = .main) {
        self.context = context
        self.callBackQueue = callBackQueue
        token = setupObserver(for: context)
    }

    deinit {
        NotificationCenter.default.removeObserver(token)
    }

    func setupObserver(for context: NSManagedObjectContext) -> NSObjectProtocol {
        return NotificationCenter.default.addObserver(forName: .NSManagedObjectContextObjectsDidChange, object: context, queue: callBackQueue) { [weak self]  _ in
            self?.changeClosure?()
        }
    }

}


final class RequestGeneratingOperationLoop {

    private let operationLoop: OperationLoop!
    private let callBackQueue: OperationQueue
    private let requestProducers: [ZMTransportRequestGenerator]
    private let transportSession: ZMTransportSession

    init(context: NSManagedObjectContext, callBackQueue: OperationQueue = .main, requestProducers: [ZMTransportRequestGenerator], transportSession: ZMTransportSession) {
        self.callBackQueue = callBackQueue
        self.requestProducers = requestProducers
        self.transportSession = transportSession
        self.operationLoop = OperationLoop(context: context, callBackQueue: callBackQueue)
        operationLoop.changeClosure = objectsDidChange
    }

    func objectsDidChange() {
        requestProducers.forEach {
            _ = transportSession.attemptToEnqueueSyncRequest(generator: $0)
        }
    }

}

