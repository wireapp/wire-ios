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

public class UserProfileUpdateRequestStrategy: AbstractRequestStrategy, ZMSingleRequestTranscoder {
    // MARK: Lifecycle

    @available(
        *,
        unavailable,
        message: "use `init(managedObjectContext:appStateDelegate:userProfileUpdateStatus)`instead"
    )
    override init(
        withManagedObjectContext managedObjectContext: NSManagedObjectContext,
        applicationStatus: ApplicationStatus
    ) {
        fatalError()
    }

    public init(
        managedObjectContext: NSManagedObjectContext,
        applicationStatus: ApplicationStatus,
        userProfileUpdateStatus: UserProfileUpdateStatus
    ) {
        self.userProfileUpdateStatus = userProfileUpdateStatus
        super.init(withManagedObjectContext: managedObjectContext, applicationStatus: applicationStatus)

        self.configuration = [
            .allowsRequestsWhileUnauthenticated,
            .allowsRequestsWhileOnline,
            .allowsRequestsDuringSlowSync,
            .allowsRequestsDuringQuickSync,
            .allowsRequestsWhileWaitingForWebsocket,
        ]

        self.passwordUpdateSync = ZMSingleRequestSync(singleRequestTranscoder: self, groupQueue: managedObjectContext)
        self.emailUpdateSync = ZMSingleRequestSync(singleRequestTranscoder: self, groupQueue: managedObjectContext)
        self.handleCheckSync = ZMSingleRequestSync(singleRequestTranscoder: self, groupQueue: managedObjectContext)
        self.handleSetSync = ZMSingleRequestSync(singleRequestTranscoder: self, groupQueue: managedObjectContext)
        self.handleSuggestionSearchSync = ZMSingleRequestSync(
            singleRequestTranscoder: self,
            groupQueue: managedObjectContext
        )
    }

    // MARK: Public

    @objc
    override public func nextRequestIfAllowed(for apiVersion: APIVersion) -> ZMTransportRequest? {
        if userProfileUpdateStatus.currentlySettingEmail ||
            userProfileUpdateStatus.currentlyChangingEmail {
            emailUpdateSync.readyForNextRequestIfNotBusy()
            return emailUpdateSync.nextRequest(for: apiVersion)
        }

        if userProfileUpdateStatus.currentlySettingPassword {
            passwordUpdateSync.readyForNextRequestIfNotBusy()
            return passwordUpdateSync.nextRequest(for: apiVersion)
        }

        if userProfileUpdateStatus.currentlyCheckingHandleAvailability {
            handleCheckSync.readyForNextRequestIfNotBusy()
            return handleCheckSync.nextRequest(for: apiVersion)
        }

        if userProfileUpdateStatus.currentlySettingHandle {
            handleSetSync.readyForNextRequestIfNotBusy()
            return handleSetSync.nextRequest(for: apiVersion)
        }

        if userProfileUpdateStatus.currentlyGeneratingHandleSuggestion {
            handleSuggestionSearchSync.readyForNextRequestIfNotBusy()
            return handleSuggestionSearchSync.nextRequest(for: apiVersion)
        }

        return nil
    }

    // MARK: - ZMSingleRequestTranscoder

    public func request(for sync: ZMSingleRequestSync, apiVersion: APIVersion) -> ZMTransportRequest? {
        switch sync {
        case passwordUpdateSync:
            let payload: NSDictionary = [
                "new_password": userProfileUpdateStatus.passwordToSet!,
            ]
            return ZMTransportRequest(
                path: "/self/password",
                method: .put,
                payload: payload,
                apiVersion: apiVersion.rawValue
            )

        case emailUpdateSync:
            let payload: NSDictionary = [
                "email": userProfileUpdateStatus.emailToSet!,
            ]
            return ZMTransportRequest(
                path: "/access/self/email",
                method: .put,
                payload: payload,
                authentication: .needsCookieAndAccessToken,
                apiVersion: apiVersion.rawValue
            )

        case handleCheckSync:
            let handle = userProfileUpdateStatus.handleToCheck!
            return ZMTransportRequest(
                path: "/users/handles/\(handle)",
                method: .head,
                payload: nil,
                apiVersion: apiVersion.rawValue
            )

        case handleSetSync:
            let payload: NSDictionary = ["handle": userProfileUpdateStatus.handleToSet!]
            return ZMTransportRequest(
                path: "/self/handle",
                method: .put,
                payload: payload,
                apiVersion: apiVersion.rawValue
            )

        case handleSuggestionSearchSync:
            guard let handlesToCheck = userProfileUpdateStatus.suggestedHandlesToCheck else {
                fatal("Tried to check handles availability, but no handle was available")
            }
            let payload = [
                "handles": handlesToCheck,
                "return": 1,
            ] as NSDictionary
            return ZMTransportRequest(
                path: "/users/handles",
                method: .post,
                payload: payload,
                apiVersion: apiVersion.rawValue
            )

        default:
            return nil
        }
    }

    public func didReceive(_ response: ZMTransportResponse, forSingleRequest sync: ZMSingleRequestSync) {
        switch sync {
        case passwordUpdateSync:
            if response.result == .success {
                userProfileUpdateStatus.didUpdatePasswordSuccessfully()
            } else if response.httpStatus == 403, response.payloadLabel() == "invalid-credentials" {
                // if the credentials are invalid, we assume that there was a previous password.
                // We decide to ignore this case because there's nothing we can do
                // and since we don't allow to change the password on the client (only to set it once),
                // this will only be fired in some edge cases
                userProfileUpdateStatus.didUpdatePasswordSuccessfully()
            } else {
                userProfileUpdateStatus.didFailPasswordUpdate()
            }

        case emailUpdateSync:
            if response.result == .success {
                userProfileUpdateStatus.didUpdateEmailSuccessfully()
            } else {
                let error: Error = NSError.invalidEmail(with: response) ??
                    NSError.keyExistsError(with: response) ??
                    NSError(userSessionErrorCode: .unknownError, userInfo: nil)
                userProfileUpdateStatus.didFailEmailUpdate(error: error)
            }

        case handleCheckSync:
            let handle = response.rawResponse?.url?.lastPathComponent ?? ""
            if response.result == .success {
                userProfileUpdateStatus.didFetchHandle(handle: handle)
            } else {
                if response.httpStatus == 404 {
                    userProfileUpdateStatus.didNotFindHandle(handle: handle)
                } else {
                    userProfileUpdateStatus.didFailRequestToFetchHandle(handle: handle)
                }
            }

        case handleSetSync:
            if response.result == .success {
                userProfileUpdateStatus.didSetHandle()
            } else {
                if NSError.handleExistsError(with: response) != nil {
                    userProfileUpdateStatus.didFailToSetAlreadyExistingHandle()
                } else {
                    userProfileUpdateStatus.didFailToSetHandle()
                }
            }

        case handleSuggestionSearchSync:
            if response.result == .success {
                if let availableHandle = (response.payload as? [String])?.first {
                    userProfileUpdateStatus.didFindHandleSuggestion(handle: availableHandle)
                } else {
                    userProfileUpdateStatus.didNotFindAvailableHandleSuggestion()
                }
            } else {
                userProfileUpdateStatus.didFailToFindHandleSuggestion()
            }

        default:
            break
        }
    }

    // MARK: Internal

    let userProfileUpdateStatus: UserProfileUpdateStatus

    // MARK: Fileprivate

    fileprivate var passwordUpdateSync: ZMSingleRequestSync! = nil

    fileprivate var emailUpdateSync: ZMSingleRequestSync! = nil

    fileprivate var handleCheckSync: ZMSingleRequestSync! = nil

    fileprivate var handleSetSync: ZMSingleRequestSync! = nil

    fileprivate var handleSuggestionSearchSync: ZMSingleRequestSync! = nil

    // MARK: Private

    /// Finds the handle that was searched for suggestion that is not in the given response
    private func findMissingHandleInResponse(response: ZMTransportResponse) -> String? {
        guard let usersPayload = response.payload as? [[String: AnyObject]] else {
            return nil
        }
        guard let possibleHandles = userProfileUpdateStatus.suggestedHandlesToCheck else {
            // this should not happen
            return nil
        }

        let existingHandles = Set(usersPayload.compactMap { $0["handle"] as? String })
        for handle in possibleHandles where !existingHandles.contains(handle) {
            return handle
        }
        return nil
    }
}
