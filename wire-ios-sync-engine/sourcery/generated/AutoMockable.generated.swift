// Generated using Sourcery 2.0.3 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
// swiftlint:disable line_length
// swiftlint:disable variable_name

import Foundation
#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit
#elseif os(OSX)
import AppKit
#endif

@testable import WireSyncEngine

class MockGenericMessageSyncInterface: GenericMessageSyncInterface {

    // MARK: - Life cycle

    // MARK: - contextChangeTrackers

    var contextChangeTrackers: [ZMContextChangeTracker] = []

    // MARK: - sync

    var syncCompletion_Invocations: [(message: GenericMessageEntity, completion: EntitySyncHandler)] = []
    var syncCompletion_MockMethod: ((GenericMessageEntity, @escaping EntitySyncHandler) -> Void)?

    func sync(_ message: GenericMessageEntity, completion: @escaping EntitySyncHandler) {
        syncCompletion_Invocations.append((message: message, completion: completion))

        guard let mock = syncCompletion_MockMethod else {
            fatalError("no mock for `syncCompletion`")
        }

        mock(message, completion)
    }

    // MARK: - nextRequest

    var nextRequestFor_Invocations: [APIVersion] = []
    var nextRequestFor_MockMethod: ((APIVersion) -> ZMTransportRequest?)?
    var nextRequestFor_MockValue: ZMTransportRequest??

    func nextRequest(for apiVersion: APIVersion) -> ZMTransportRequest? {
        nextRequestFor_Invocations.append(apiVersion)

        if let mock = nextRequestFor_MockMethod {
            return mock(apiVersion)
        } else if let mock = nextRequestFor_MockValue {
            return mock
        } else {
            fatalError("no mock for `nextRequestFor`")
        }
    }

    // MARK: - expireMessages

    var expireMessagesWithDependency_Invocations: [NSObject] = []
    var expireMessagesWithDependency_MockMethod: ((NSObject) -> Void)?

    func expireMessages(withDependency dependency: NSObject) {
        expireMessagesWithDependency_Invocations.append(dependency)

        guard let mock = expireMessagesWithDependency_MockMethod else {
            fatalError("no mock for `expireMessagesWithDependency`")
        }

        mock(dependency)
    }

}
