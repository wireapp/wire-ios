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
import WireDataModel
import WireRequestStrategy

struct ZMUserSessionBuilder {

    private var analytics: AnalyticsType?
    private var appVersion: String?
    private var application: ZMApplication?
    private var configuration: ZMUserSession.Configuration?
    private var coreDataStack: CoreDataStack?
    private var cryptoboxMigrationManager: CryptoboxMigrationManagerInterface?
    private var earService: EARServiceInterface?
    private var eventProcessor: UpdateEventProcessor?
    private var flowManager: FlowManagerType?
    private var mediaManager: MediaManagerType?
    private var mlsService: MLSServiceInterface?
    private var observeMLSGroupVerificationStatusUseCase: ObserveMLSGroupVerificationStatusUseCaseProtocol?
    private var operationLoop: ZMOperationLoop?
    private var proteusToMLSMigrationCoordinator: ProteusToMLSMigrationCoordinating?
    private var sharedUserDefaults: UserDefaults?
    private var strategyDirectory: StrategyDirectoryProtocol?
    private var syncStrategy: ZMSyncStrategy?
    private var transportSession: TransportSessionType?
    private var userId: UUID?
    private var useCaseFactory: UseCaseFactoryProtocol?

    // MARK: - Initialize

    init() { }

    // MARK: - Build

    func build() -> ZMUserSession {
        assert(analytics != nil, "expected 'analytics' to be set!)")
        assert(appVersion != nil, "expected 'appVersion' to be set!)")
        assert(application != nil, "expected 'application' to be set!)")
        assert(configuration != nil, "expected 'configuration' to be set!)")
        assert(coreDataStack != nil, "expected 'coreDataStack' to be set!)")
        assert(cryptoboxMigrationManager != nil, "expected 'cryptoboxMigrationManager' to be set!)")
        assert(earService != nil, "expected 'earService' to be set!)")
        assert(eventProcessor != nil, "expected 'eventProcessor' to be set!)")
        assert(flowManager != nil, "expected 'flowManager' to be set!)")
        assert(mediaManager != nil, "expected 'mediaManager' to be set!)")
        assert(mlsService != nil, "expected 'mlsService' to be set!)")
        assert(observeMLSGroupVerificationStatusUseCase != nil, "expected 'observeMLSGroupVerificationStatusUseCase' to be set!)")
        assert(operationLoop != nil, "expected 'operationLoop' to be set!)")
        assert(proteusToMLSMigrationCoordinator != nil, "expected 'proteusToMLSMigrationCoordinator' to be set!)")
        assert(sharedUserDefaults != nil, "expected 'sharedUserDefaults' to be set!)")
        assert(strategyDirectory != nil, "expected 'strategyDirectory' to be set!)")
        assert(syncStrategy != nil, "expected 'syncStrategy' to be set!)")
        assert(transportSession != nil, "expected 'transportSession' to be set!)")
        assert(userId != nil, "expected 'userId' to be set!)")
        assert(useCaseFactory != nil, "expected 'useCaseFactory' to be set!)")

        return ZMUserSession(
            userId: userId!,
            transportSession: transportSession!,
            mediaManager: mediaManager!,
            flowManager: flowManager!,
            analytics: analytics!,
            eventProcessor: eventProcessor!,
            strategyDirectory: strategyDirectory!,
            syncStrategy: syncStrategy!,
            operationLoop: operationLoop!,
            application: application!,
            appVersion: appVersion!,
            coreDataStack: coreDataStack!,
            configuration: configuration!,
            earService: earService!,
            mlsService: mlsService!,
            cryptoboxMigrationManager: cryptoboxMigrationManager!,
            proteusToMLSMigrationCoordinator: proteusToMLSMigrationCoordinator!,
            sharedUserDefaults: sharedUserDefaults!,
            useCaseFactory: useCaseFactory!,
            observeMLSGroupVerificationStatus: observeMLSGroupVerificationStatusUseCase!
        )
    }

    // MARK: - Setup Dependencies

    mutating func withAppVersion(_ appVersion: String) -> ZMUserSessionBuilder {
        self.appVersion = appVersion
        return self
    }

    mutating func withApplication(_ application: ZMApplication) -> ZMUserSessionBuilder {
        self.application = application
        return self
    }

    mutating func withConfiguration(_ configuration: ZMUserSession.Configuration) -> ZMUserSessionBuilder {
        self.configuration = configuration
        return self
    }

    mutating func withCoreDataStack(_ coreDataStack: CoreDataStack) -> ZMUserSessionBuilder {
        self.coreDataStack = coreDataStack
        return self
    }

    mutating func withCryptoboxMigrationManager(_ cryptoboxMigrationManager: CryptoboxMigrationManagerInterface) -> ZMUserSessionBuilder {
        self.cryptoboxMigrationManager = cryptoboxMigrationManager
        return self
    }

    mutating func withEARService(_ earService: EARServiceInterface) -> ZMUserSessionBuilder {
        self.earService = earService
        return self
    }

    mutating func withEventProcessor(_ eventProcessor: UpdateEventProcessor) -> ZMUserSessionBuilder {
        self.eventProcessor = eventProcessor
        return self
    }

    mutating func withFlowManager(_ flowManager: FlowManagerType) -> ZMUserSessionBuilder {
        self.flowManager = flowManager
        return self
    }

    mutating func withMediaManager(_ mediaManager: MediaManagerType) -> ZMUserSessionBuilder {
        self.mediaManager = mediaManager
        return self
    }

    mutating func withMLSService(_ mlsService: MLSServiceInterface) -> ZMUserSessionBuilder {
        self.mlsService = mlsService
        return self
    }

    mutating func withObserveMLSGroupVerificationStatusUseCase(_ observeMLSGroupVerificationStatusUseCase: ObserveMLSGroupVerificationStatusUseCaseProtocol) -> ZMUserSessionBuilder {
        self.observeMLSGroupVerificationStatusUseCase = observeMLSGroupVerificationStatusUseCase
        return self
    }

    mutating func withOperationLoop(_ operationLoop: ZMOperationLoop) -> ZMUserSessionBuilder {
        self.operationLoop = operationLoop
        return self
    }

    mutating func withProteusToMLSMigrationCoordinator(_ proteusToMLSMigrationCoordinator: ProteusToMLSMigrationCoordinating) -> ZMUserSessionBuilder {
        self.proteusToMLSMigrationCoordinator = proteusToMLSMigrationCoordinator
        return self
    }

    mutating func withSharedUserDefaults(_ sharedUserDefaults: UserDefaults) -> ZMUserSessionBuilder {
        self.sharedUserDefaults = sharedUserDefaults
        return self
    }

    mutating func withStrategyDirectory(_ strategyDirectory: StrategyDirectoryProtocol) -> ZMUserSessionBuilder {
        self.strategyDirectory = strategyDirectory
        return self
    }

    mutating func withSyncStrategy(syncStrategy: ZMSyncStrategy) -> ZMUserSessionBuilder {
        self.syncStrategy = syncStrategy
        return self
    }

    mutating func withTransportSession(_ transportSession: TransportSessionType) -> ZMUserSessionBuilder {
        self.transportSession = transportSession
        return self
    }

    mutating func withUserID(_ userId: UUID) -> ZMUserSessionBuilder {
        self.userId = userId
        return self
    }

    mutating func withUseCaseFactory(_ useCaseFactory: UseCaseFactoryProtocol) -> ZMUserSessionBuilder {
        self.useCaseFactory = useCaseFactory
        return self
    }
}
