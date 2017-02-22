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
import ZMTransport.ZMRequestCancellation


class StrategyFactory {

    let syncContext: NSManagedObjectContext
    let registrationStatus: ClientRegistrationStatus
    let cancellationProvider: ZMRequestCancellation

    init(syncContext: NSManagedObjectContext, registrationStatus: ClientRegistrationStatus, cancellationProvider: ZMRequestCancellation) {
        self.syncContext = syncContext
        self.registrationStatus = registrationStatus
        self.cancellationProvider = cancellationProvider
    }

    func createStrategies() -> [AnyObject] {
        return [
            createMissingClientsStrategy(),
            createClientMessageTranscoder(),
            createImageUploadRequestStrategy(),
            createFileUploadRequestStrategy(),
            createLinkPreviewAssetUploadRequestStrategy(),
            createLinkPreviewUploadRequestStrategy()
        ]
    }

    private func createMissingClientsStrategy() -> MissingClientsRequestStrategy {
        return MissingClientsRequestStrategy(
            clientRegistrationStatus: registrationStatus,
            apnsConfirmationStatus: DeliveryConfirmationDummy(),
            managedObjectContext: syncContext
        )
    }

    private func createClientMessageTranscoder() -> ZMClientMessageTranscoder {
        return ZMClientMessageTranscoder(
            managedObjectContext: syncContext,
            localNotificationDispatcher: PushMessageHandlerDummy(),
            clientRegistrationStatus: registrationStatus,
            apnsConfirmationStatus: DeliveryConfirmationDummy()
        )!
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

    private func createLinkPreviewAssetUploadRequestStrategy() -> LinkPreviewAssetUploadRequestStrategy {
        return LinkPreviewAssetUploadRequestStrategy(clientRegistrationDelegate: registrationStatus, managedObjectContext: syncContext)
    }

    private func createLinkPreviewUploadRequestStrategy() -> LinkPreviewUploadRequestStrategy {
        return LinkPreviewUploadRequestStrategy(managedObjectContext: syncContext, clientRegistrationDelegate: registrationStatus)
    }

}
