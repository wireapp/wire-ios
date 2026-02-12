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

import Foundation
import WireLogging

extension ZMUserSession {

    /// Whether the user completed the registration on this device

    @objc public var registeredOnThisDevice: Bool {
        managedObjectContext.registeredOnThisDevice
    }

    @objc(setEmailCredentials:)
    func setEmailCredentials(_ emailCredentials: UserEmailCredentials?) {
        applicationStatusDirectory.clientRegistrationStatus.emailCredentials = emailCredentials
    }

    public func reportEndToEndIdentityEnrollmentSuccess() {
        syncManagedObjectContext.performAndWait {
            applicationStatusDirectory.clientRegistrationStatus.didEnrollIntoEndToEndIdentity()
            RequestAvailableNotification.notifyNewRequestsAvailable(nil)
        }
    }

    /// `True` if the session is ready to be used.
    ///
    /// NOTE: This property should only be called on the main queue.

    public var isLoggedIn: Bool {
        let needsToRegisterClient = ZMClientRegistrationStatus.needsToRegisterClient(in: managedObjectContext)
        let needsToRegisterMLSClient = applicationStatusDirectory.clientRegistrationStatus
            .needsToRegisterMLSClient(in: managedObjectContext)
        let waitingToRegisterMLSClient = needsToRegisterMLSClient && !hasCompletedInitialSync

        return isAuthenticated && !needsToRegisterClient && !waitingToRegisterMLSClient
    }

    /// `True` if the session has a valid authentication cookie

    var isAuthenticated: Bool {
        transportSession.cookieStorage.hasAuthenticationCookie
    }

    /// This will delete user data stored by WireSyncEngine in the keychain.

    func deleteUserKeychainItems() {
        transportSession.cookieStorage.deleteKeychainItems()
    }

    /// Logout the current user
    ///
    /// - parameter deleteCookie: If set to true the cookies associated with the session will be deleted
    /// - parameter completion: called after the user session has been closed

    func close(deleteCookie: Bool, completion: @escaping () -> Void) {
        // Clear all notifications associated with the account from the notification center
        syncManagedObjectContext.performGroupedBlock { [weak self] in
            self?.localNotificationDispatcher?.cancelAllNotifications()
        }

        if deleteCookie {
            deleteUserKeychainItems()
        }

        // Call tearDown directly (not in perform block)
        // Network services are explicitly invalidated in tearDown before closing Core Data
        tearDown()

        completion()
    }

    func close(deleteCookie: Bool) async {
        await withCheckedContinuation { continuation in
            var resumed = false
            close(deleteCookie: deleteCookie) {
                guard !resumed else { return }
                resumed = true
                continuation.resume()
            }
        }
    }

    public func logout(credentials: UserEmailCredentials, _ completion: @escaping (Result<Void, Error>) -> Void) {
        guard
            let accountID = ZMUser.selfUser(in: viewContext).remoteIdentifier,
            let selfClientIdentifier = ZMUser.selfUser(in: viewContext).selfClient()?.remoteIdentifier,
            let apiVersion = resolvedBackendMetadata.apiVersion
        else {
            return
        }

        WireLogger.sessionManager.info("logout: starting logout sequence")

        // Step 1 & 2: Stop all sync and work processing before sending DELETE request
        Task { [weak self] in
            guard let self else { return }

            WireLogger.sessionManager.info("logout: suspending syncAgent")
            await self.syncAgent?.terminate()
            WireLogger.sessionManager.info("logout: syncAgent suspended")

            // Nil out syncAgent to prevent resume() calls
            self.syncAgent = nil
            WireLogger.sessionManager.info("logout: syncAgent cleared")

            // Cancel and wait for post-sync task to complete
            if let postSyncTask = self.postSyncTask {
                WireLogger.sessionManager.info("logout: cancelling post-sync task")
                postSyncTask.cancel()
                _ = await postSyncTask.result
                self.postSyncTask = nil
                WireLogger.sessionManager.info("logout: post-sync task cancelled and completed")
            }

            if let workAgent = self.clientSessionComponent?.workAgent {
                WireLogger.sessionManager.info("logout: clearing workAgent queue")
                await workAgent.clearSchedulerQueue()
                WireLogger.sessionManager.info("logout: stopping workAgent")
                await workAgent.stop()
                WireLogger.sessionManager.info("logout: workAgent stopped")
            }

            // Step 3: Send DELETE request
            WireLogger.sessionManager.info("logout: sending DELETE client request")
            let payload: [String: Any] = if let password = credentials.password, !password.isEmpty {
                ["password": password]
            } else {
                [:]
            }

            let request = ZMTransportRequest(
                path: "/clients/\(selfClientIdentifier)",
                method: .delete,
                payload: payload as ZMTransportData,
                apiVersion: apiVersion.rawValue
            )

            request.add(ZMCompletionHandler(on: self.managedObjectContext, block: { [weak self] response in
                guard let self else { return }

                // Step 4: Stop operationLoop and transportSession (both success and failure)
                WireLogger.sessionManager.info("logout: DELETE response received, stopping operationLoop and transportSession")
                self.operationLoop?.tearDown()
                WireLogger.sessionManager.info("logout: operationLoop torn down")
                self.operationLoop = nil
                WireLogger.sessionManager.info("logout: operationLoop nil")
                self.transportSession.tearDown()
                WireLogger.sessionManager.info("logout: transportSession torn down")

                if response.httpStatus == 200 {
                    self.delegate?.userDidLogout(accountId: accountID)
                    completion(.success(()))
                } else {
                    completion(.failure(self.errorFromFailedDeleteResponse(response)))
                }
            }))

            self.transportSession.enqueueOneTime(request)
        }
    }

    func errorFromFailedDeleteResponse(_ response: ZMTransportResponse!) -> NSError {

        let errorCode: UserSessionErrorCode = switch response.result {
        case .permanentError:
            switch response.payload?.asDictionary()?["label"] as? String {
            case "client-not-found":
                .clientDeletedRemotely
            case "invalid-credentials",
                 "missing-auth",
                 "bad-request": // in case the password does not match password format requirement
                .invalidCredentials
            default:
                .unknownError
            }
        case .temporaryError, .tryAgainLater, .expired:
            .networkError
        default:
            .unknownError
        }

        var userInfo: [String: Any]?
        if let transportSessionError = response.transportSessionError {
            userInfo = [NSUnderlyingErrorKey: transportSessionError]
        }

        return NSError(userSessionErrorCode: errorCode, userInfo: userInfo)
    }

}
