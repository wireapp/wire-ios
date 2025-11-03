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

import Foundation
import GenericMessageProtocol
import WireLinkPreview
import WireLegacyLogging

public final class LinkPreviewDetectorHelper: NSObject {
    fileprivate static var _test_debug_linkPreviewDetector: LinkPreviewDetectorType?

    public static func test_debug_linkPreviewDetector() -> LinkPreviewDetectorType? {
        _test_debug_linkPreviewDetector
    }

    public static func setTest_debug_linkPreviewDetector(_ detectorType: LinkPreviewDetectorType?) {
        _test_debug_linkPreviewDetector = detectorType
    }

    public static func tearDown() {
        _test_debug_linkPreviewDetector = nil
    }

}

private let zmLog = ZMSLog(tag: "link previews")

extension ZMImagePreprocessingTracker {
    static func createPreviewImagePreprocessingTracker(managedObjectContext: NSManagedObjectContext)
        -> ZMImagePreprocessingTracker! {
        let imageFetchPredicate = NSPredicate(
            format: "%K == %d",
            ZMClientMessage.linkPreviewStateKey,
            ZMLinkPreviewState.downloaded.rawValue
        )
        let needsProccessing = NSPredicate { object, _ in
            guard let message = object as? ZMClientMessage else { return false }
            return managedObjectContext.zm_fileAssetCache.hasOriginalImageData(for: message)
        }

        return ZMImagePreprocessingTracker(
            managedObjectContext: managedObjectContext,
            imageProcessingQueue: OperationQueue(),
            fetch: imageFetchPredicate,
            needsProcessingPredicate: needsProccessing,
            entityClass: ZMClientMessage.self
        )
    }
}

public final class LinkPreviewAssetUploadRequestStrategy: AbstractRequestStrategy, ZMContextChangeTrackerSource {

    let requestFactory = AssetRequestFactory()
    private let featureRepository: LegacyFeatureRepository

    /// Processors
    fileprivate let linkPreviewPreprocessor: LinkPreviewPreprocessor
    // swiftlint:disable:next todo_requires_jira_link
    fileprivate let previewImagePreprocessor: ZMImagePreprocessingTracker // TODO: replace with AssetPreprocessor

    /// Upstream sync
    fileprivate var assetUpstreamSync: ZMUpstreamModifiedObjectSync!
    let localDomain: String?
    private let isCloudDomain: Bool

    private var shouldUploadExtraMetaData: Bool {
        guard !isCloudDomain else { return false }
        return managedObjectContext.performAndWait {
            featureRepository.fetchAssetAuditLog().status == .enabled
        }
    }

    @available(*, unavailable)
    public override init(
        withManagedObjectContext managedObjectContext: NSManagedObjectContext,
        applicationStatus: ApplicationStatus
    ) {
        fatalError()
    }

    public init(
        managedObjectContext: NSManagedObjectContext,
        applicationStatus: ApplicationStatus,
        linkPreviewPreprocessor: LinkPreviewPreprocessor?,
        previewImagePreprocessor: ZMImagePreprocessingTracker?,
        localDomain: String?,
        isCloudDomain: Bool
    ) {
        if LinkPreviewDetectorHelper.test_debug_linkPreviewDetector() == nil {
            LinkPreviewDetectorHelper.setTest_debug_linkPreviewDetector(LinkPreviewDetector())
        }
        self.linkPreviewPreprocessor = linkPreviewPreprocessor ?? LinkPreviewPreprocessor(
            linkPreviewDetector: LinkPreviewDetectorHelper.test_debug_linkPreviewDetector()!,
            managedObjectContext: managedObjectContext
        )
        self.previewImagePreprocessor = previewImagePreprocessor ?? ZMImagePreprocessingTracker
            .createPreviewImagePreprocessingTracker(managedObjectContext: managedObjectContext)
        self.featureRepository = LegacyFeatureRepository(context: managedObjectContext)
        self.localDomain = localDomain
        self.isCloudDomain = isCloudDomain

        super.init(withManagedObjectContext: managedObjectContext, applicationStatus: applicationStatus)

        self.assetUpstreamSync = ZMUpstreamModifiedObjectSync(
            transcoder: self,
            entityName: ZMClientMessage.entityName(),
            update: predicateForAssetUpload,
            filter: filterForAssetUpload,
            keysToSync: [ZMClientMessage.linkPreviewStateKey],
            managedObjectContext: managedObjectContext
        )
    }

    var predicateForAssetUpload: NSPredicate {
        NSPredicate(format: "%K == %d", ZMClientMessage.linkPreviewStateKey, ZMLinkPreviewState.processed.rawValue)
    }

    var filterForAssetUpload: NSPredicate {
        NSPredicate { [unowned self] object, _ in
            guard let message = object as? ZMClientMessage else {
                return false
            }

            return managedObjectContext.zm_fileAssetCache.hasEncryptedMediumImageData(for: message)
        }
    }

    public var contextChangeTrackers: [ZMContextChangeTracker] {
        [linkPreviewPreprocessor, previewImagePreprocessor, assetUpstreamSync]
    }

    public override func nextRequestIfAllowed(for apiVersion: APIVersion) -> ZMTransportRequest? {
        assetUpstreamSync.nextRequest(for: apiVersion)
    }
}

extension LinkPreviewAssetUploadRequestStrategy: ZMUpstreamTranscoder {

    public func request(
        forUpdating managedObject: ZMManagedObject,
        forKeys keys: Set<String>,
        apiVersion: APIVersion
    ) -> ZMUpstreamRequest? {
        guard
            let message = managedObject as? ZMClientMessage,
            keys.contains(ZMClientMessage.linkPreviewStateKey)
        else {
            return nil
        }

        let logAttributes: LogAttributes = [
            .public: true,
            .nonce: message.nonce?.safeForLoggingDescription ?? "<nil>"
        ]

        guard let conversation = message.conversation else {
            WireLogger.assets.warn(
                "Trying to send message that doesn't have a conversation",
                attributes: logAttributes
            )
            return nil
        }

        let retention = AssetRequestFactory.Retention(conversation: conversation)

        guard let imageData = managedObjectContext.zm_fileAssetCache.encryptedMediumImageData(for: message) else {
            return nil
        }

        var extraMetaData: AssetRequestFactory.AssetAuditLogMetaData?
        if shouldUploadExtraMetaData {
            guard let domain = conversation.domain ?? localDomain else {
                WireLogger.assets.warn(
                    "should include extra metadata for link preview but not able to",
                    attributes: logAttributes
                )
                return nil
            }

            let conversationID = QualifiedID(
                uuid: conversation.remoteIdentifier,
                domain: domain
            )

            let image = SendableImage(
                name: nil,
                utType: nil,
                data: imageData
            )

            extraMetaData = .init(
                conversationID: conversationID,
                fileName: image.name,
                mimeType: image.utType?.preferredMIMEType
            )
        }

        return ZMUpstreamRequest(
            keys: [ZMClientMessage.linkPreviewStateKey],
            transportRequest: requestFactory.upstreamRequestForAsset(
                withData: imageData,
                retention: retention,
                assetAuditLogMetaData: extraMetaData,
                apiVersion: apiVersion
            )
        )
    }

    public func request(
        forInserting managedObject: ZMManagedObject,
        forKeys keys: Set<String>?,
        apiVersion: APIVersion
    ) -> ZMUpstreamRequest? {
        nil
    }

    public func shouldProcessUpdatesBeforeInserts() -> Bool {
        false
    }

    public func objectToRefetchForFailedUpdate(of managedObject: ZMManagedObject) -> ZMManagedObject? {
        nil
    }

    public func updateUpdatedObject(
        _ managedObject: ZMManagedObject,
        requestUserInfo: [AnyHashable: Any]?,
        response: ZMTransportResponse,
        keysToParse: Set<String>
    ) -> Bool {
        guard let message = managedObject as? ZMClientMessage else { return false }
        guard keysToParse.contains(ZMClientMessage.linkPreviewStateKey) else { return false }
        guard let payload = response.payload?.asDictionary(),
              let assetKey = payload["key"] as? String else { fatal("No asset ID present in payload") }

        if var linkPreview = message.underlyingMessage?.linkPreviews.first, !message.isObfuscated,
           let messageText = message.textMessageData?.messageText,
           let mentions = message.textMessageData?.mentions {

            let assetToken = payload["token"] as? String
            let assetDomain = payload["domain"] as? String
            linkPreview.update(withAssetKey: assetKey, assetToken: assetToken, assetDomain: assetDomain)

            let updatedText = Text.with {
                $0.content = messageText
                $0.mentions = mentions.compactMap { $0.convertToProtosMention() }
                $0.linkPreview = [linkPreview]
            }

            let genericMessage = GenericMessage(
                content: updatedText,
                nonce: message.nonce!,
                expiresAfterTimeInterval: message.deletionTimeout
            )

            do {
                try message.setUnderlyingMessage(genericMessage)
            } catch {
                zmLog.warn("Failed to update genericMessage. Reason: \(error.localizedDescription)")
                return true
            }

            zmLog
                .debug(
                    "did upload image for: \(message.nonce?.uuidString ?? "nil"), genericMessage: \(String(describing: message.underlyingMessage))"
                )
            zmLog.debug("setting state to .uploaded for: \(message.nonce?.uuidString ?? "nil")")
            message.linkPreviewState = .uploaded
            return true
        } else {
            zmLog
                .debug(
                    "did upload image for: \(message.nonce?.uuidString ?? "nil") but message is missing link preview: \(String(describing: message.underlyingMessage))"
                )
            zmLog.debug("setting state to .done for: \(message.nonce?.uuidString ?? "nil")")
            message.linkPreviewState = .done
            return false
        }
    }

    public func updateInsertedObject(
        _ managedObject: ZMManagedObject,
        request upstreamRequest: ZMUpstreamRequest,
        response: ZMTransportResponse
    ) {
        // nop
    }

}
