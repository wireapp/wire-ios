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

import avs
import WireDataModel
import WireDomain
import WireLogging
import WireNetwork

open class AuthenticatedSessionFactory {

    let currentAppVersion: String
    let currentBuildNumber: String
    let mediaManager: MediaManagerType
    let flowManager: FlowManagerType
    let application: ZMApplication
    let minTLSVersion: String?

    public init(
        currentAppVersion: String,
        currentBuildNumber: String,
        application: ZMApplication,
        mediaManager: MediaManagerType,
        flowManager: FlowManagerType,
        minTLSVersion: String?
    ) {
        self.currentAppVersion = currentAppVersion
        self.currentBuildNumber = currentBuildNumber
        self.mediaManager = mediaManager
        self.flowManager = flowManager
        self.application = application
        self.minTLSVersion = minTLSVersion
    }

    func session(
        for account: Account,
        coreDataStack: CoreDataStack,
        restNetworkService: NetworkService,
        webSocketNetworkService: NetworkService,
        backendMetadata: ResolvedBackendMetadata,
        backendEnvironment: BackendEnvironment2,
        proxyCredentials: WireNetwork.ProxyCredentials?,
        configuration: ZMUserSession.Configuration,
        sharedUserDefaults: UserDefaults,
        isDeveloperModeEnabled: Bool,
        journal: Journal,
        logFilesProvider: LogFilesProviding
    ) -> ZMUserSession? {
        let selfClientID = ZMUser.selfUser(in: coreDataStack.viewContext).selfClient()?.remoteIdentifier
        let environment = BackendEnvironment(backendEnvironment)

        let transportSession = ZMTransportSession(
            environment: environment,
            proxyUsername: proxyCredentials?.username,
            proxyPassword: proxyCredentials?.password,
            cookieStorage: environment.cookieStorage(for: account),
            reachability: environment.reachabilityWrapper(),
            initialAccessToken: nil,
            applicationGroupIdentifier: nil,
            applicationVersion: currentBuildNumber,
            minTLSVersion: minTLSVersion,
            selfClientID: selfClientID,
            isSyncV2Enabled: journal[.isSyncV2Enabled]
        )

        let cryptoboxMigrationManager = CryptoboxMigrationManager()
        let coreCryptoKeyMigrationManager = CoreCryptoKeyMigrationManager(journal: journal)

        let coreCryptoProvider = CoreCryptoProvider(
            selfUserID: account.userIdentifier,
            sharedContainerURL: coreDataStack.applicationContainer,
            accountDirectory: coreDataStack.accountContainer,
            syncContext: coreDataStack.syncContext,
            cryptoboxMigrationManager: cryptoboxMigrationManager,
            coreCryptoKeyMigrationManager: coreCryptoKeyMigrationManager
        )

        var userSessionBuilder = ZMUserSessionBuilder()
        userSessionBuilder.withAllDependencies(
            restNetworkService: restNetworkService,
            webSocketNetworkService: webSocketNetworkService,
            backendMetadata: backendMetadata,
            currentAppVersion: currentAppVersion,
            currentBuildNumber: currentBuildNumber,
            application: application,
            cryptoboxMigrationManager: CryptoboxMigrationManager(),
            coreDataStack: coreDataStack,
            coreCryptoProvider: coreCryptoProvider,
            configuration: configuration,
            contextStorage: LAContextStorage(),
            earService: nil,
            flowManager: flowManager,
            mediaManager: mediaManager,
            mlsService: nil,
            proteusToMLSMigrationCoordinator: nil,
            recurringActionService: nil,
            sharedUserDefaults: sharedUserDefaults,
            sharedContainerURL: coreDataStack.applicationContainer,
            transportSession: transportSession,
            userId: account.userIdentifier,
            journal: journal,
            logFilesProvider: logFilesProvider
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
