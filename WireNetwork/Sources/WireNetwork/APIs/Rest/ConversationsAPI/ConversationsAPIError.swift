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

/// Errors originating from `ConversationsAPI`.
public enum ConversationsAPIError: Error {

    /// Failure if functionality has not been implemented.
    case notImplemented

    /// Failure if http body is invalid.
    case invalidBody

    /// Unsupported endpoint for API version
    case unsupportedEndpointForAPIVersion

    /// MLS not enabled
    case mlsNotEnabled

    /// Users not connected
    case usersNotConnected

    /// Failure if user and domain are empty
    case userAndDomainShouldNotBeEmpty

    /// Access denied
    case accessDenied

    /// Conversation not found
    case conversationNotFound

    /// Team not found
    case teamNotFound

    /// Conversation code not found
    case conversationCodeNotFound

    /// Conversation guests links disabled
    case guestLinksDisabled

    /// Invalid conversation id
    case invalidConversationID

    /// Non empty member list
    case nonEmptyMemberList

    /// Missing legalhold consent
    case missingLegalHoldConsent

    /// Operation denied
    case operationDenied

    /// Requesting user is not a team member
    case noTeamMember

    /// Not connected
    case notConnected

    /// Unsupported conversation group type for API endpoint
    case unsupportedChannelCreationForAPIEndpoint

    /// Non federating backends
    case nonFederatingBackends([String])

    /// Unreachable backends
    case unreachableBackends

    /// Insufficient authorizations
    case insufficientAuthorization

    /// Insufficient permissions
    case insufficientPermissions

    /// Invalid operation
    case invalidOperation

    /// Permission unchanged
    case permissionsUnchanged

    /// An illegal argument was passed.
    case illegalArgument(message: String)

}
