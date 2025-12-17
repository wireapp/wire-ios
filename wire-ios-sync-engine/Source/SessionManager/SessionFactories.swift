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

    var environment: WireTransport.BackendEnvironment
    var reachability: Reachability

    let minTLSVersion: String?

    public init(
        currentAppVersion: String,
        currentBuildNumber: String,
        application: ZMApplication,
        mediaManager: MediaManagerType,
        flowManager: FlowManagerType,
        environment: WireTransport.BackendEnvironment,
        proxyUsername: String?,
        proxyPassword: String?,
        reachability: Reachability,
        minTLSVersion: String?
    ) {
        self.currentAppVersion = currentAppVersion
        self.currentBuildNumber = currentBuildNumber
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
        isDeveloperModeEnabled: Bool,
        journal: Journal,
        logFilesProvider: LogFilesProviding
    ) -> ZMUserSession? {
        let wireAPIBackendEnvironment = BackendEnvironment(
            url: environment.backendURL,
            webSocketURL: environment.backendWSURL,
            blacklistURL: environment.blackListURL,
            pinnedKeys: environment.trustData.map { trustData in
                PinnedKey(
                    key: trustData.certificateKey,
                    rawKey: trustData.rawCertificateKey,
                    hosts: trustData.hosts.map { host in
                        switch host.rule {
                        case .equals:
                            .equals(host.value)
                        case .endsWith:
                            .endsWith(host.value)
                        }
                    }
                )
            },
            proxySettings: proxySettings
        )

        let selfClientID = ZMUser.selfUser(in: coreDataStack.viewContext).selfClient()?.remoteIdentifier

        let transportSession = ZMTransportSession(
            environment: environment,
            proxyUsername: proxyUsername,
            proxyPassword: proxyPassword,
            cookieStorage: environment.cookieStorage(for: account),
            reachability: reachability,
            initialAccessToken: nil,
            applicationGroupIdentifier: nil,
            applicationVersion: currentBuildNumber,
            minTLSVersion: minTLSVersion,
            selfClientID: selfClientID,
            isSyncV2Enabled: journal[.isSyncV2Enabled]
        )

        let coreCryptoKeyMigrationManager = CoreCryptoKeyMigrationManager(journal: journal)

        let coreCryptoProvider = CoreCryptoProvider(
            selfUserID: account.userIdentifier,
            sharedContainerURL: coreDataStack.applicationContainer,
            accountDirectory: coreDataStack.accountContainer,
            sharedUserDefaults: sharedUserDefaults,
            syncContext: coreDataStack.syncContext,
            coreCryptoKeyMigrationManager: coreCryptoKeyMigrationManager,
            localDomain: BackendInfo.domain
        )

        var userSessionBuilder = ZMUserSessionBuilder()
        userSessionBuilder.withAllDependencies(
            backendEnvironment: environment,
            wireAPIBackendEnvironment: wireAPIBackendEnvironment,
            currentAppVersion: currentAppVersion,
            currentBuildNumber: currentBuildNumber,
            application: application,
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
            minTLSVersion: minTLSVersion,
            journal: journal,
            logFilesProvider: logFilesProvider
        )

        let userSession = userSessionBuilder.build()
        userSession.setup(
            apiVersion: nil,
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

    private var proxySettings: WireNetwork.ProxySettings? {
        guard let proxy = environment.proxy else { return nil }

        if proxy.needsAuthentication {
            guard let proxyUsername, let proxyPassword else {
                fatalInternal("Proxy needs authentication but credentials are missing")
                return nil
            }

            return .authenticated(host: proxy.host, port: proxy.port, username: proxyUsername, password: proxyPassword)
        } else {
            return .unauthenticated(host: proxy.host, port: proxy.port)
        }
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
