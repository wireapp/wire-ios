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
    private var observeMLSGroupVerificationStatus: ObserveMLSGroupVerificationStatusUseCaseProtocol?
    private var operationLoop: ZMOperationLoop?
    private var proteusToMLSMigrationCoordinator: ProteusToMLSMigrationCoordinating?
    private var sharedUserDefaults: UserDefaults?
    private var strategyDirectory: StrategyDirectoryProtocol?
    private var syncStrategy: ZMSyncStrategy?
    private var transportSession: TransportSessionType?
    private var userId: UUID?
    private var useCaseFactory: UseCaseFactoryProtocol?

    init() { }

    func build() -> ZMUserSession {
        ZMUserSession(
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
            observeMLSGroupVerificationStatus: observeMLSGroupVerificationStatus!
        )
    }
}
