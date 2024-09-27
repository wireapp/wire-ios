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

// MARK: - InviteResult

public enum InviteResult {
    case success(email: String)
    case failure(email: String, error: InviteError)
}

// MARK: - InviteError

public enum InviteError: Int, Error {
    /// There's more invitations sent than available seats
    case tooManyTeamInvitations
    /// The given e-mail address has been blacklisted due to a permanent bounce or a complaint.
    case blacklistedEmail
    ///  Invalid e-mail address.
    case invalidEmail
    /// The user has no verified identity (email or phone number).
    case noIdentity
    /// The user doesn't have a verified email address.
    case noEmail
    /// The e-mail address is already associated with a Wire account
    case alreadyRegistered
    /// The invite has been cancelled.
    case cancelled
    /// Couldn't parse server response
    case unknown
}

// MARK: - InviteResult + Equatable

extension InviteResult: Equatable {}

public func == (lhs: InviteResult, rhs: InviteResult) -> Bool {
    switch (lhs, rhs) {
    case let (InviteResult.success(email: lhsEmail), InviteResult.success(email: rhsEmail)):
        lhsEmail == rhsEmail
    case let (
        InviteResult.failure(email: lhsEmail, error: lhsError),
        InviteResult.failure(email: rhsEmail, error: rhsError)
    ):
        lhsEmail == rhsEmail && lhsError == rhsError
    default:
        false
    }
}

public typealias InviteCompletionHandler = (InviteResult) -> Void

// MARK: - TeamInvitationStatus

public class TeamInvitationStatus: NSObject {
    fileprivate var pendingInvitations: [String: InviteCompletionHandler] = [:]
    fileprivate var processedInvitations: [String: InviteCompletionHandler] = [:]

    func invite(_ email: String, completionHandler: @escaping InviteCompletionHandler) {
        pendingInvitations[email] = completionHandler
        RequestAvailableNotification.notifyNewRequestsAvailable(nil)
    }

    func retry(_ email: String) {
        if let completionHandler = processedInvitations.removeValue(forKey: email) {
            pendingInvitations[email] = completionHandler
        }
    }

    func nextEmail() -> String? {
        if let next = pendingInvitations.popFirst() {
            processedInvitations[next.key] = next.value
            return next.key
        }

        return nil
    }

    func handle(result: InviteResult, email: String) {
        processedInvitations[email]?(result)
        processedInvitations.removeValue(forKey: email)
    }
}
