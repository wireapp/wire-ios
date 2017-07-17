//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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
import avs
import WireTransport
import WireUtilities

private let log = ZMSLog(tag: "SessionManager")

@objc
public protocol SessionManagerDelegate : class {
    
    func sessionManagerCreated(unauthenticatedSession : UnauthenticatedSession)
    func sessionManagerCreated(userSession : ZMUserSession)
    func sessionManagerWillStartMigratingLocalStore()
}

@objc
public class SessionManager : NSObject {

    public typealias LaunchOptions = [UIApplicationLaunchOptionsKey : Any]

    public let appGroupIdentifier: String
    public let appVersion: String
    public let mediaManager: AVSMediaManager
    public var analytics: AnalyticsType?
    var apnsEnvironment : ZMAPNSEnvironment?
    let application : ZMApplication
    var transportSession: ZMTransportSession? // TODO: Who should own this?
    public weak var delegate : SessionManagerDelegate? = nil
    var authenticationToken: ZMAuthenticationObserverToken?
    var userSession: ZMUserSession?
    var unauthenticatedSession: UnauthenticatedSession?
    private let accountManager: AccountManager
    fileprivate let environment: ZMBackendEnvironment
    
    public init(appGroupIdentifier: String,
                appVersion: String,
                apnsEnvironment: ZMAPNSEnvironment? = nil,
                mediaManager: AVSMediaManager,
                analytics: AnalyticsType?,
                delegate: SessionManagerDelegate?,
                application: ZMApplication,
                launchOptions: LaunchOptions) {
        
        SessionManager.enableLogsByEnvironmentVariable()
        ZMBackendEnvironment.setupEnvironments()
        
        self.appGroupIdentifier = appGroupIdentifier
        self.appVersion = appVersion
        self.apnsEnvironment = apnsEnvironment
        self.application = application
        self.mediaManager = mediaManager
        self.analytics = analytics
        self.delegate = delegate

        let sharedContainerURL = SessionManager.sharedContainerURL(with: appGroupIdentifier)!
        accountManager = AccountManager(sharedDirectory: sharedContainerURL)
        environment = ZMBackendEnvironment(userDefaults: .standard)

        super.init()
        authenticationToken = ZMUserSessionAuthenticationNotification.addObserver(self)

        select(account: accountManager.selectedAccount) { session in
            session.application(application, didFinishLaunchingWithOptions: launchOptions)
            if let url = launchOptions[.url] as? URL {
                session.didLaunch(with: url)
            }
        }
    }

    private func select(account: Account?, completion: @escaping (ZMUserSession) -> Void) {
        if let account = account { // TODO: Add check if store exists?
            let createSession = { [weak self] in
                guard let `self` = self else { return }
                guard let session = self.session(for: account) else { preconditionFailure("Unable to create session for \(account)") }
                self.userSession = session
                self.delegate?.sessionManagerCreated(userSession: session)
                completion(session)
            }

            if ZMUserSession.needsToPrepareLocalStore(usingAppGroupIdentifier: appGroupIdentifier) {
                delegate?.sessionManagerWillStartMigratingLocalStore()
                ZMUserSession.prepareLocalStore(usingAppGroupIdentifier: appGroupIdentifier) {
                    DispatchQueue.main.async(execute: createSession)
                }
            } else {
                createSession()
            }
        } else {
            createUnauthenticatedSession()
        }
    }

    private func session(for account: Account) -> ZMUserSession? {
        let transportSession = ZMTransportSession(
            baseURL: environment.backendURL,
            websocketURL: environment.backendWSURL,
            cookieStorage: .init(forServerName: environment.backendURL.host!, userIdentifier: account.userIdentifier),
            initialAccessToken: nil,
            sharedContainerIdentifier: nil
        )

        return ZMUserSession(
            mediaManager: mediaManager,
            analytics: analytics,
            transportSession: transportSession,
            apnsEnvironment: apnsEnvironment,
            application: application,
            userId: nil,
            appVersion: appVersion,
            appGroupIdentifier: appGroupIdentifier
        )
    }

    private func createUnauthenticatedSession() {
        do {
            let unauthenticatedSession = try UnauthenticatedSession(backendURL: environment.backendURL, delegate: self)
            self.unauthenticatedSession = unauthenticatedSession
            delegate?.sessionManagerCreated(unauthenticatedSession: unauthenticatedSession)
        } catch {
            fatal("Can't create unauthenticated session: \(error)")
        }
    }

    deinit {
        if let authenticationToken = authenticationToken {
            ZMUserSessionAuthenticationNotification.removeObserver(for: authenticationToken)
        }
        
        userSession?.tearDown()
    }
    
    public var isLoggedIn: Bool {
        return accountManager.selectedAccount.flatMap {
            ZMPersistentCookieStorage(forServerName: environment.backendURL.host!, userIdentifier: $0.userIdentifier)
        }?.authenticationCookieData != nil
    }
    
    var storeExists: Bool {
        // TODO: For which account? Does this check still make sense? We can check if we have a cookie / account for a user id,
        // if we have a cookie but no DB then something weird is going on, but we should just create a new database either way.
        guard let storeURL = ZMUserSession.storeURL(forAppGroupIdentifier: appGroupIdentifier) else { return false }
        return NSManagedObjectContext.storeExists(at: storeURL)
    }
    
    @objc public var currentUser: ZMUser? {
        guard let userSession = userSession else { return nil }
        return ZMUser.selfUser(in: userSession.managedObjectContext)
    }
    
    @objc public var isUserSessionActive: Bool {
        return userSession != nil
    }

    func updateProfileImage(imageData: Data) {
        userSession?.enqueueChanges {
            self.userSession?.profileUpdate.updateImage(imageData: imageData)
        }
    }

    static private func sharedContainerURL(with appGroupIdentifier: String) -> URL? {
        if let sharedContainerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) {
            return sharedContainerURL
        } else {
            // Seems like the shared container is not available. This can happen for multiple reasons:
            // 1. The app is compiled with an incorrect provisioning profile (for example by a 3rd party)
            // 2. The app is running on simulator and there is no correct provisioning profile on the system
            // 3. There is another issue with code signing
            //
            // The app should allow not having a shared container in the first 2 cases, in the 3rd case the app should crash
            let environment = ZMDeploymentEnvironment().environmentType()
            if TARGET_IPHONE_SIMULATOR == 0 && (environment == .appStore || environment == .internal) {
                fatal("Unable to create shared container url using app group identifier: \(appGroupIdentifier)")
            } else {
                log.error("Unable to create shared containerwith deployment environment: \(environment.rawValue)")
                log.error("Wire is going to use the APPLICATION SUPPORT directory to store user data")
                return FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            }
        }
    }

}

// MARK: - UnauthenticatedSessionDelegate

extension SessionManager: UnauthenticatedSessionDelegate {
    func session(session: UnauthenticatedSession, updatedCredentials credentials: ZMCredentials) {
        if let userSession = userSession, let emailCredentials = credentials as? ZMEmailCredentials {
            userSession.setEmailCredentials(emailCredentials)
        }
    }
    
    func session(session: UnauthenticatedSession, updatedProfileImage imageData: Data) {
        updateProfileImage(imageData: imageData)
    }
}

// MARK: - ZMAuthenticationObserver

extension SessionManager: ZMAuthenticationObserver {
    
    @objc public func authenticationDidFail(_ error: Error) {
        guard unauthenticatedSession == nil else { return }
        do {
            let unauthenticatedSession = try UnauthenticatedSession(backendURL: environment.backendURL, delegate: self)
            self.unauthenticatedSession = unauthenticatedSession
            delegate?.sessionManagerCreated(unauthenticatedSession: unauthenticatedSession)
        } catch {
            fatal("Can't create unauthenticated session: \(error)")
        }
    }
    
    @objc public func authenticationDidSucceed() {
        guard self.userSession == nil, let authenticationStatus = unauthenticatedSession?.authenticationStatus else {
            return RequestAvailableNotification.notifyNewRequestsAvailable(self)
        }
        
        let userSession = ZMUserSession(mediaManager: mediaManager,
                                        analytics: analytics,
                                        transportSession: transportSession,
                                        apnsEnvironment: apnsEnvironment,
                                        application: application,
                                        userId:nil,
                                        appVersion: appVersion,
                                        appGroupIdentifier: appGroupIdentifier)!
        self.userSession = userSession
        userSession.setEmailCredentials(authenticationStatus.emailCredentials())
        
        userSession.syncManagedObjectContext.performGroupedBlock {
            userSession.syncManagedObjectContext.registeredOnThisDevice = authenticationStatus.completedRegistration
        }
        
        if let profileImageData =  authenticationStatus.profileImageData {
            updateProfileImage(imageData: profileImageData)
        }
        
        self.delegate?.sessionManagerCreated(userSession: userSession)
    }
}
