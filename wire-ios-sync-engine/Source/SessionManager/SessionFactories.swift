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

import avs
import WireAPI
import WireDataModel

open class AuthenticatedSessionFactory {

    let appVersion: String
    let mediaManager: MediaManagerType
    let flowManager: FlowManagerType
    let application: ZMApplication

    var environment: BackendEnvironmentProvider
    var reachability: Reachability

    let minTLSVersion: String?

    public init(
        appVersion: String,
        application: ZMApplication,
        authenticationManager: AuthenticationManagerProtocol,
        mediaManager: MediaManagerType,
        flowManager: FlowManagerType,
        environment: BackendEnvironmentProvider,
        proxyUsername: String?,
        proxyPassword: String?,
        reachability: Reachability,
        minTLSVersion: String?
    ) {
        self.appVersion = appVersion
        self.mediaManager = mediaManager
        self.flowManager = flowManager
        self.application = application
        self.environment = environment
        self.proxyUsername = proxyUsername
        self.proxyPassword = proxyPassword
        self.reachability = reachability
        self.minTLSVersion = minTLSVersion
    }

    func session(
        for account: Account,
        coreDataStack: CoreDataStack,
        configuration: ZMUserSession.Configuration,
        sharedUserDefaults: UserDefaults,
        isDeveloperModeEnabled: Bool
    ) -> ZMUserSession? {
        let apiServiceFactory = { (clientID: String, userID: String) in

            let authenticationManager = AuthenticationManager(
                clientID: clientID,
                cookieStorage,
                networkService: NetworkService(),
            )

            APIService(
                backendURL: environment.backendURL,
                // TODO: Use the authentication storage from https://github.com/wireapp/wire-ios/pull/2084
                authenticationManager: authenticationManager,
                minTLSVersion: WireAPI.TLSVersion.minVersionFrom(minTLSVersion)
            )
        }
        let transportSession = ZMTransportSession(
            environment: environment,
            proxyUsername: proxyUsername,
            proxyPassword: proxyPassword,
            cookieStorage: environment.cookieStorage(for: account),
            reachability: reachability,
            initialAccessToken: nil,
            applicationGroupIdentifier: nil,
            applicationVersion: appVersion,
            minTLSVersion: minTLSVersion
        )

        var userSessionBuilder = ZMUserSessionBuilder()
        userSessionBuilder.withAllDependencies(
            apiServiceFactory: apiServiceFactory,
            appVersion: appVersion,
            application: application,
            cryptoboxMigrationManager: CryptoboxMigrationManager(),
            coreDataStack: coreDataStack,
            configuration: configuration,
            contextStorage: LAContextStorage(),
            earService: nil,
            flowManager: flowManager,
            mediaManager: mediaManager,
            mlsService: nil,
            proteusToMLSMigrationCoordinator: nil,
            recurringActionService: nil,
            sharedUserDefaults: sharedUserDefaults,
            transportSession: transportSession,
            userId: account.userIdentifier
        )

        let userSession = userSessionBuilder.build()
        userSession.setup(
            eventProcessor: nil,
            strategyDirectory: nil,
            syncStrategy: nil,
            operationLoop: nil,
            configuration: configuration,
            isDeveloperModeEnabled: isDeveloperModeEnabled
        )
        userSession.startRequestLoopTracker()

        return userSession
    }

    public func updateProxy(username: String?, password: String?) {
        proxyUsername = username
        proxyPassword = password
    }

    // MARK: - Private

    private(set) var proxyUsername: String?
    private(set) var proxyPassword: String?
}

// MARK: -

open class UnauthenticatedSessionFactory {

    var environment: BackendEnvironmentProvider
    var reachability: Reachability

    var readyForRequests: Bool = false
    let appVersion: String

    init(
        appVersion: String,
        environment: BackendEnvironmentProvider,
        proxyUsername: String?,
        proxyPassword: String?,
        reachability: Reachability
    ) {
        self.environment = environment
        self.proxyUsername = proxyUsername
        self.proxyPassword = proxyPassword
        self.reachability = reachability
        self.appVersion = appVersion
    }

    func session(
        delegate: UnauthenticatedSessionDelegate,
        authenticationStatusDelegate: ZMAuthenticationStatusDelegate
    ) -> UnauthenticatedSession {
        let transportSession = UnauthenticatedTransportSession(
            environment: environment,
            proxyUsername: proxyUsername,
            proxyPassword: proxyPassword,
            reachability: reachability,
            applicationVersion: appVersion,
            readyForRequests: readyForRequests
        )

        return UnauthenticatedSession(
            transportSession: transportSession,
            reachability: reachability,
            delegate: delegate,
            authenticationStatusDelegate: authenticationStatusDelegate,
            userPropertyValidator: UserPropertyValidator()
        )
    }

    public func updateProxy(username: String?, password: String?) {
        proxyUsername = username
        proxyPassword = password
    }

    // MARK: - Private

    private var proxyUsername: String?
    private var proxyPassword: String?
}
