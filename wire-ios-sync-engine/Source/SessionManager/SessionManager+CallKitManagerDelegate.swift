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

import CallKit
import Foundation
import WireLogging
import WireSystem

enum ConversationLookupError: Error {
    case accountDoesNotExist
    case conversationDoesNotExist
    case failedToProcessCallEvents
}

extension SessionManager: CallKitManagerDelegate {

    func lookupConversation(
        by handle: CallHandle,
        completionHandler: @escaping (Result<ZMConversation, Error>) -> Void
    ) {
        WireLogger.calling.info("lookup conversation for: \(handle)")
        guard let account = accountManager.account(with: handle.accountID) else {
            return completionHandler(.failure(ConversationLookupError.accountDoesNotExist))
        }

        Task { @MainActor in
            guard
                let userSession = try? await withSession(for: account),
                let conversation = ZMConversation.fetch(
                    with: handle.conversationID,
                    in: userSession.managedObjectContext
                )
            else {
                return completionHandler(.failure(ConversationLookupError.conversationDoesNotExist))
            }

            completionHandler(.success(conversation))
        }
    }

    func lookupConversationAndProcessPendingCallEvents(
        by handle: CallHandle,
        completionHandler: @escaping (Result<ZMConversation, Error>) -> Void
    ) {
        WireLogger.calling.info("lookup conversation and process pending call events for: \(handle)")

        guard let account = accountManager.account(with: handle.accountID) else {
            return completionHandler(.failure(ConversationLookupError.accountDoesNotExist))
        }

        Task { @MainActor in
            guard
                let userSession = try? await withSession(for: account),
                let conversation = ZMConversation.fetch(
                    with: handle.conversationID,
                    in: userSession.managedObjectContext
                )
            else {
                return completionHandler(.failure(ConversationLookupError.conversationDoesNotExist))
            }

            await requestCallConfigIfNeeded(for: userSession)
            await userSession.processPendingCallEvents()

            WireLogger.calling.info("did process call events, returning conversation...")
            completionHandler(.success(conversation))
        }
    }

    /// Proactively requests call config for a background session.
    /// This ensures the session has fresh call configuration when handling incoming calls.
    /// - Parameter session: The user session to request config for
    private func requestCallConfigIfNeeded(for session: ZMUserSession) async {
        guard session != activeUserSession else { return }

        session.managedObjectContext.performGroupedBlock {
            guard let callCenter = session.callCenter else {
                WireLogger.calling.warn("Cannot request call config: callCenter not available")
                return
            }

            WireLogger.calling.info("Proactively requesting call config for background session.")
            callCenter.requestCallConfig()
        }
    }

    func endAllCalls() {
        for userSession in backgroundUserSessions.values {
            userSession.viewContext.perform {
                userSession.callCenter?.endAllCalls()
            }
        }
    }

    func didEndAllCalls() {
        WireLogger.calling.info("all calls ended, suspending background tasks", attributes: .safePublic)
        Task {
            for userSession in backgroundUserSessions.values {
                await userSession.syncAgent?.suspend()
            }
        }
    }

}
