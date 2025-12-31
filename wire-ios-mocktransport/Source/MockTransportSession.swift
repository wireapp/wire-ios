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

import CoreData
import Foundation
import WireTransport

public extension MockTransportSession {
    private func selfUserPartOfTeam(_ team: MockTeam) -> Bool {
        team.contains(user: selfUser)
    }

    private func ascendingCreationDate(first: MockTeam, second: MockTeam) -> Bool {
        first.createdAt < second.createdAt
    }
}

// MARK: - Conversations

extension MockTransportSession {

    func relevant(conversations: Set<NSManagedObject>) -> [MockConversation] {
        conversations
            .compactMap { object -> MockConversation? in
                object as? MockConversation
            }.filter { conversation -> Bool in
                conversation.type != .invalid && conversation.selfIdentifier == self.selfUser.identifier
            }
    }
}

extension MockTransportSession: UnauthenticatedTransportSessionProtocol {

    public func enqueueRequest(withGenerator generator: () -> ZMTransportRequest?) -> EnqueueResult {
        let result = attemptToEnqueueSyncRequest(generator: generator)

        if !result.didHaveLessRequestThanMax {
            return .maximumNumberOfRequests
        } else if !result.didGenerateNonNullRequest {
            return .nilRequest
        } else {
            return .success
        }
    }

    public var environment: BackendEnvironmentProvider {
        MockEnvironment()
    }
}

// MARK: - Email activation

public extension MockTransportSession {
    @objc var emailActivationCode: String {
        "123456"
    }
}

extension MockTransportSession: TransportSessionType {

    public func enqueue(_ request: ZMTransportRequest, queue: GroupQueue) async -> ZMTransportResponse {
        await withCheckedContinuation { continuation in
            request.add(ZMCompletionHandler(on: queue, block: { response in
                continuation.resume(returning: response)
            }))

            enqueueOneTime(request)
        }
    }

    public var accessTokenHandler: ZMAccessTokenHandler {
        ZMAccessTokenHandler()
    }

    public var requestLoopDetectionCallback: ((String) -> Void)? {
        get { nil }
        set {}
    }

    public func addCompletionHandlerForBackgroundSession(identifier: String, handler: @escaping () -> Void) {}
}

public extension MockTransportSession {

    @objc var invalidSinceParameter400: UUID {
        UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB")!
    }

    @objc var unknownSinceParameter404: UUID {
        UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!
    }
}

public extension NSString {

    @objc
    func removingAPIVersion() -> NSString {
        for version in APIVersion.allCases {
            if version == .v0 {
                continue
            }
            let prefix = "/v\(version.rawValue)"
            if hasPrefix(prefix) {
                return replacingOccurrences(of: prefix, with: "") as NSString
            }
        }
        return self
    }
}
