//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
import WireMessageStrategy
import WireRequestStrategy
import ZMTransport.ZMRequestCancellation


class StrategyFactory {

    let syncContext: NSManagedObjectContext
    let registrationStatus: ClientRegistrationStatus
    let cancellationProvider: ZMRequestCancellation
    private(set) var strategies = [AnyObject]()

    private var tornDown = false

    init(syncContext: NSManagedObjectContext, registrationStatus: ClientRegistrationStatus, cancellationProvider: ZMRequestCancellation) {
        self.syncContext = syncContext
        self.registrationStatus = registrationStatus
        self.cancellationProvider = cancellationProvider
        self.strategies = createStrategies()
    }

    deinit {
        precondition(tornDown, "Need to call `tearDown` before `deinit`")
    }

    func tearDown() {
        strategies.forEach {
            if $0.responds(to: #selector(ZMObjectSyncStrategy.tearDown)) {
                ($0 as? ZMObjectSyncStrategy)?.tearDown()
            }
        }
        tornDown = true
    }

    private func createStrategies() -> [AnyObject] {
        return [
            // Missing Clients
            createMissingClientsStrategy(),

            // Client Messages
            createClientMessageTranscoder(),

            // Link Previews
            createLinkPreviewAssetUploadRequestStrategy(),
            createLinkPreviewUploadRequestStrategy(),

            // Assets V2
            createImageUploadRequestStrategy(),
            createFileUploadRequestStrategy(),

            // Assets V3
            createAssetClientMessageRequestStrategy(),
            createAssetV3ImageUploadRequestStrategy(),
            createAssetV3FileUploadRequestStrategy()
        ]
    }

    private func createMissingClientsStrategy() -> MissingClientsRequestStrategy {
        return MissingClientsRequestStrategy(
            clientRegistrationStatus: registrationStatus,
            apnsConfirmationStatus: DeliveryConfirmationDummy(),
            managedObjectContext: syncContext
        )
    }

    private func createClientMessageTranscoder() -> ClientMessageTranscoder {
        return ClientMessageTranscoder(
            in: syncContext,
            localNotificationDispatcher: PushMessageHandlerDummy(),
            clientRegistrationStatus: registrationStatus,
            apnsConfirmationStatus: DeliveryConfirmationDummy()
        )
    }

    private func createImageUploadRequestStrategy() -> ImageUploadRequestStrategy {
        return ImageUploadRequestStrategy(
            clientRegistrationStatus: registrationStatus,
            managedObjectContext: syncContext,
            maxConcurrentImageOperation: 1
        )
    }

    private func createFileUploadRequestStrategy() -> FileUploadRequestStrategy {
        return FileUploadRequestStrategy(
            clientRegistrationStatus: registrationStatus,
            managedObjectContext: syncContext,
            taskCancellationProvider: cancellationProvider
        )
    }

    // MARK: – Link Previews

    private func createLinkPreviewAssetUploadRequestStrategy() -> LinkPreviewAssetUploadRequestStrategy {
        return LinkPreviewAssetUploadRequestStrategy(
            clientRegistrationDelegate: registrationStatus,
            managedObjectContext: syncContext
        )
    }

    private func createLinkPreviewUploadRequestStrategy() -> LinkPreviewUploadRequestStrategy {
        return LinkPreviewUploadRequestStrategy(
            managedObjectContext: syncContext,
            clientRegistrationDelegate: registrationStatus
        )
    }

    // MARK: - Asset V3

    private func createAssetV3FileUploadRequestStrategy() -> AssetV3FileUploadRequestStrategy {
        return AssetV3FileUploadRequestStrategy(
            clientRegistrationStatus: registrationStatus,
            taskCancellationProvider: cancellationProvider,
            managedObjectContext: syncContext
        )
    }

    private func createAssetV3ImageUploadRequestStrategy() -> AssetV3ImageUploadRequestStrategy {
        return AssetV3ImageUploadRequestStrategy(
            clientRegistrationStatus: registrationStatus,
            taskCancellationProvider: cancellationProvider,
            managedObjectContext: syncContext
        )
    }

    private func createAssetClientMessageRequestStrategy() -> AssetClientMessageRequestStrategy {
        return AssetClientMessageRequestStrategy(
            clientRegistrationStatus: registrationStatus,
            managedObjectContext: syncContext
        )
    }
}
