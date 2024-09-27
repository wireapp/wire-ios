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
import WireLinkPreview
import WireRequestStrategy
import WireTransport.ZMRequestCancellation

final class StrategyFactory {
    // MARK: Lifecycle

    init(
        syncContext: NSManagedObjectContext,
        applicationStatus: ApplicationStatus,
        linkPreviewPreprocessor: LinkPreviewPreprocessor,
        transportSession: TransportSessionType
    ) {
        let httpClient = HttpClientImpl(transportSession: transportSession, queue: syncContext)
        let apiProvider = APIProvider(httpClient: httpClient)
        let sessionEstablisher = SessionEstablisher(context: syncContext, apiProvider: apiProvider)
        let messageDependencyResolver = MessageDependencyResolver(context: syncContext)
        let quickSyncObserver = QuickSyncObserver(
            context: syncContext,
            applicationStatus: applicationStatus,
            notificationContext: syncContext.notificationContext
        )
        self.linkPreviewPreprocessor = linkPreviewPreprocessor
        self.syncContext = syncContext
        self.applicationStatus = applicationStatus
        self.messageSender = MessageSender(
            apiProvider: apiProvider,
            clientRegistrationDelegate: applicationStatus.clientRegistrationDelegate,
            sessionEstablisher: sessionEstablisher,
            messageDependencyResolver: messageDependencyResolver,
            quickSyncObserver: quickSyncObserver,
            context: syncContext
        )
        self.strategies = createStrategies(linkPreviewPreprocessor: linkPreviewPreprocessor)
    }

    deinit {
        precondition(tornDown, "Need to call `tearDown` before `deinit`")
    }

    // MARK: Internal

    unowned let syncContext: NSManagedObjectContext
    let applicationStatus: ApplicationStatus
    let linkPreviewPreprocessor: LinkPreviewPreprocessor
    let messageSender: MessageSenderInterface
    private(set) var strategies = [AnyObject]()

    func tearDown() {
        for strategy in strategies {
            if strategy.responds(to: #selector(ZMObjectSyncStrategy.tearDown)) {
                (strategy as? ZMObjectSyncStrategy)?.tearDown()
            }
        }
        tornDown = true
    }

    // MARK: Private

    private var tornDown = false

    private func createStrategies(linkPreviewPreprocessor: LinkPreviewPreprocessor) -> [AnyObject] {
        [
            // Clients
            createFetchingClientsStrategy(),
            createVerifyLegalHoldStrategy(),

            // Client Messages
            createClientMessageRequestStrategy(),

            // Link Previews
            createLinkPreviewAssetUploadRequestStrategy(linkPreviewPreprocessor: linkPreviewPreprocessor),
            createLinkPreviewUpdateRequestStrategy(),

            // Assets V3
            createAssetClientMessageRequestStrategy(),
            createAssetV3UploadRequestStrategy(),
        ]
    }

    private func createVerifyLegalHoldStrategy() -> VerifyLegalHoldRequestStrategy {
        VerifyLegalHoldRequestStrategy(withManagedObjectContext: syncContext, applicationStatus: applicationStatus)
    }

    private func createFetchingClientsStrategy() -> FetchingClientRequestStrategy {
        FetchingClientRequestStrategy(withManagedObjectContext: syncContext, applicationStatus: applicationStatus)
    }

    private func createClientMessageRequestStrategy() -> ClientMessageRequestStrategy {
        ClientMessageRequestStrategy(
            context: syncContext,
            localNotificationDispatcher: PushMessageHandlerDummy(),
            applicationStatus: applicationStatus,
            messageSender: messageSender
        )
    }

    // MARK: – Link Previews

    private func createLinkPreviewAssetUploadRequestStrategy(linkPreviewPreprocessor: LinkPreviewPreprocessor)
        -> LinkPreviewAssetUploadRequestStrategy {
        LinkPreviewAssetUploadRequestStrategy(
            managedObjectContext: syncContext,
            applicationStatus: applicationStatus,
            linkPreviewPreprocessor: linkPreviewPreprocessor,
            previewImagePreprocessor: nil
        )
    }

    private func createLinkPreviewUpdateRequestStrategy() -> LinkPreviewUpdateRequestStrategy {
        LinkPreviewUpdateRequestStrategy(managedObjectContext: syncContext, messageSender: messageSender)
    }

    // MARK: - Asset V3

    private func createAssetV3UploadRequestStrategy() -> AssetV3UploadRequestStrategy {
        let strategy = AssetV3UploadRequestStrategy(
            withManagedObjectContext: syncContext,
            applicationStatus: applicationStatus
        )

        // WORKAROUND:
        // There are some issues with uploading file using a background session from the share extension.
        // It's not clear exactly why, but we've observed that sometimes when sending an asset, we get up to
        // the point of sending the asset upload request (using a background session) but we don't get the
        // response until up to a minute later. However, if we observe the network traffic using a tool like
        // proxyman, the response is returned almost immediately. For some reason it doesn't get delivered
        // to the url session that made the request until later. It may be an issue outside of our control,
        // possible with an iOS version.
        //
        // The workaround is to avoid using a backgound session for the upload request. The file will be
        // uploaded using a normal foreground session instead. The share extension doesn't dismiss anyway
        // until all uploads are complete, so a background session is not technically needed.
        strategy.shouldUseBackgroundSession = false

        return strategy
    }

    private func createAssetClientMessageRequestStrategy() -> AssetClientMessageRequestStrategy {
        AssetClientMessageRequestStrategy(managedObjectContext: syncContext, messageSender: messageSender)
    }
}
