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

// MARK: - ZMAssetClientMessage

/// An asset message (image, file, ...)
@objcMembers
public class ZMAssetClientMessage: ZMOTRMessage {
    // MARK: Lifecycle

    convenience init(
        asset: WireProtos.Asset,
        nonce: UUID,
        managedObjectContext: NSManagedObjectContext,
        expiresAfter timeout: TimeInterval?
    ) throws {
        self.init(nonce: nonce, managedObjectContext: managedObjectContext)

        self.transferState = .uploading
        self.version = 3

        let genericMessage = GenericMessage(content: asset, nonce: nonce, expiresAfterTimeInterval: timeout)
        try mergeWithExistingData(message: genericMessage)
    }

    // MARK: Public

    /// Current download / upload progress
    @NSManaged public var progress: Float

    /// True if we are current in the process of downloading the asset
    @NSManaged public var isDownloading: Bool

    /// State of the file transfer from the uploader's perspective
    @NSManaged public internal(set) var transferState: AssetTransferState

    /// The asset endpoint version used to generate this message
    /// values lower than 3 represent an enpoint version of 2
    @NSManaged public var version: Int16

    override public var hashOfContent: Data? {
        guard let serverTimestamp else {
            return nil
        }

        return underlyingMessage?.hashOfContent(with: serverTimestamp)
    }

    /// Remote asset ID
    public var assetId: UUID? {
        get { transientUUID(forKey: #keyPath(ZMAssetClientMessage.assetId)) }
        set { setTransientUUID(newValue, forKey: #keyPath(ZMAssetClientMessage.assetId)) }
    }

    /// Preprocessed size of image
    public var preprocessedSize: CGSize {
        get { transientCGSize(forKey: #keyPath(ZMAssetClientMessage.preprocessedSize)) }
        set { setTransientCGSize(newValue, forKey: #keyPath(ZMAssetClientMessage.preprocessedSize)) }
    }

    /// Original file size
    public var size: UInt64 {
        guard let asset = underlyingMessage?.assetData else {
            return 0
        }
        let originalSize = asset.original.size
        let previewSize = asset.preview.size

        if originalSize == 0 {
            return previewSize
        }
        return originalSize
    }

    /// Download state
    public var downloadState: AssetDownloadState {
        if hasDownloadedFile {
            .downloaded
        } else if isDownloading {
            .downloading
        } else {
            .remote
        }
    }

    /// Whether the image preview has been downloaded
    public var hasDownloadedPreview: Bool {
        asset?.hasDownloadedPreview ?? false
    }

    /// Whether the file has been downloaded
    public var hasDownloadedFile: Bool {
        asset?.hasDownloadedFile ?? false
    }

    // Wheather the referenced asset is encrypted
    public var hasEncryptedAsset: Bool {
        var hasEncryptionKeys = false

        if fileMessageData != nil {
            if let remote = underlyingMessage?.assetData?.preview.remote, remote.hasOtrKey {
                hasEncryptionKeys = true
            }
        } else if imageMessageData != nil {
            if let imageAsset = mediumGenericMessage?.imageAssetData, imageAsset.hasOtrKey {
                hasEncryptionKeys = true
            }
        }

        return hasEncryptionKeys
    }

    /// Used to associate and persist the task identifier of the `NSURLSessionTask`
    /// with the upload or download of the file data. Can be used to verify that the
    /// data of a `FileMessage` is being down- or uploaded after a termination event
    public var associatedTaskIdentifier: ZMTaskIdentifier? {
        get {
            let key = #keyPath(ZMAssetClientMessage.associatedTaskIdentifier_data)
            willAccessValue(forKey: key)
            let data = primitiveValue(forKey: key) as? Data
            didAccessValue(forKey: key)
            return data.flatMap { ZMTaskIdentifier(from: $0) }
        }
        set {
            let key = #keyPath(ZMAssetClientMessage.associatedTaskIdentifier_data)
            willChangeValue(forKey: key)
            setPrimitiveValue(newValue?.data, forKey: key)
            didChangeValue(forKey: key)
        }
    }

    override public var isUpdatingExistingMessage: Bool {
        guard let genericMessage = underlyingMessage,
              let content = genericMessage.content else {
            return false
        }
        switch content {
        case .edited, .reaction:
            return true
        default:
            return false
        }
    }

    override public var isSilenced: Bool {
        conversation?.isMessageSilenced(underlyingMessage, senderID: sender?.remoteIdentifier) ?? true
    }

    public static func keyPathsForValuesAffectingAssetID() -> Set<String> {
        [#keyPath(ZMAssetClientMessage.assetID_data)]
    }

    public static func keyPathsForValuesPreprocessedSize() -> Set<String> {
        [#keyPath(ZMAssetClientMessage.assetID_data)]
    }

    public func updateTransferState(_ transferState: AssetTransferState, synchronize: Bool) {
        self.transferState = transferState

        if synchronize {
            setLocallyModifiedKeys([#keyPath(ZMAssetClientMessage.transferState)])
        }
    }

    override public func expire() {
        super.expire()

        if transferState != .uploaded {
            transferState = .uploadingFailed
        }
    }

    override public func markAsSent() {
        super.markAsSent()
        setObfuscationTimerIfNeeded()
    }

    override public func resend() {
        if transferState != .uploaded {
            transferState = .uploading
        }

        progress = 0
        setLocallyModifiedKeys([#keyPath(ZMAssetClientMessage.transferState)])

        super.resend()
    }

    override public func update(withPostPayload payload: [AnyHashable: Any], updatedKeys: Set<AnyHashable>?) {
        if let serverTimestamp = (payload as NSDictionary).optionalDate(forKey: "time") {
            self.serverTimestamp = serverTimestamp
            expectsReadConfirmation = conversation?.hasReadReceiptsEnabled ?? false
        }

        conversation?.updateTimestampsAfterUpdatingMessage(self)

        // NOTE: Calling super since this is method overriden to handle special cases when receiving an asset
        super.startDestructionIfNeeded()
    }

    // MARK: Internal

    /// In memory cache
    var cachedUnderlyingAssetMessage: GenericMessage?

    var v2Asset: V2Asset? {
        V2Asset(with: self)
    }

    var v3Asset: V3Asset? {
        V3Asset(with: self)
    }

    var asset: AssetProxyType? {
        v2Asset ?? v3Asset
    }

    static func keyPathsForValuesAffectingAssociatedTaskIdentifier() -> Set<String> {
        [#keyPath(ZMAssetClientMessage.associatedTaskIdentifier_data)]
    }

    func setObfuscationTimerIfNeeded() {
        guard isEphemeral else {
            return
        }

        startDestructionIfNeeded()
    }

    // MARK: Fileprivate

    // Private implementation
    @NSManaged fileprivate var assetID_data: Data
    @NSManaged fileprivate var preprocessedSize_data: Data
    @NSManaged fileprivate var associatedTaskIdentifier_data: Data
}

// MARK: - Core data

extension ZMAssetClientMessage {
    override public func awakeFromInsert() {
        super.awakeFromInsert()
        cachedUnderlyingAssetMessage = nil
    }

    override public func awakeFromFetch() {
        super.awakeFromFetch()
        cachedUnderlyingAssetMessage = nil
    }

    override public func awake(fromSnapshotEvents flags: NSSnapshotEventType) {
        super.awake(fromSnapshotEvents: flags)
        cachedUnderlyingAssetMessage = nil
    }

    override public func didTurnIntoFault() {
        super.didTurnIntoFault()
        cachedUnderlyingAssetMessage = nil
    }

    override public static func entityName() -> String {
        "AssetClientMessage"
    }

    override public var ignoredKeys: Set<AnyHashable>? {
        (super.ignoredKeys ?? Set())
            .union([
                #keyPath(ZMAssetClientMessage.assetID_data),
                #keyPath(ZMAssetClientMessage.preprocessedSize_data),
                #keyPath(ZMAssetClientMessage.hasDownloadedPreview),
                #keyPath(ZMAssetClientMessage.hasDownloadedFile),
                #keyPath(ZMAssetClientMessage.dataSet),
                #keyPath(ZMAssetClientMessage.downloadState),
                #keyPath(ZMAssetClientMessage.progress),
                #keyPath(ZMAssetClientMessage.associatedTaskIdentifier_data),
                #keyPath(ZMAssetClientMessage.version),
            ])
    }

    override public static func predicateForObjectsThatNeedToBeUpdatedUpstream() -> NSPredicate? {
        nil
    }
}

// MARK: - AssetClientMessageDataType

@objc
public enum AssetClientMessageDataType: UInt {
    case placeholder = 1
    case fullAsset = 2
    case thumbnail = 3
}

// MARK: - AssetDownloadState

@objc
public enum AssetDownloadState: Int16 {
    case remote = 0
    case downloaded
    case downloading
}

// MARK: - AssetTransferState

@objc
public enum AssetTransferState: Int16 {
    case uploading = 0
    case uploaded
    case uploadingFailed
    case uploadingCancelled
}

// MARK: - AssetProcessingState

@objc
public enum AssetProcessingState: Int16 {
    case done = 0
    case preprocessing
    case uploading
}

// MARK: - CacheAsset

struct CacheAsset: AssetType {
    // MARK: Lifecycle

    init(owner: ZMAssetClientMessage, type: AssetType, cache: FileAssetCache) {
        self.owner = owner
        self.type = type
        self.cache = cache
    }

    // MARK: Internal

    enum AssetType {
        case image
        case file
        case thumbnail
    }

    var owner: ZMAssetClientMessage
    var type: AssetType
    var cache: FileAssetCache

    var needsPreprocessing: Bool {
        switch type {
        case .file:
            false
        case .image,
             .thumbnail:
            true
        }
    }

    var hasOriginal: Bool {
        if case .file = type {
            cache.hasOriginalFileData(for: owner)
        } else {
            cache.hasOriginalImageData(for: owner)
        }
    }

    var original: Data? {
        if case .file = type {
            cache.originalFileData(for: owner)
        } else {
            cache.originalImageData(for: owner)
        }
    }

    var hasPreprocessed: Bool {
        guard needsPreprocessing else {
            return false
        }
        return cache.hasMediumImageData(for: owner)
    }

    var preprocessed: Data? {
        guard needsPreprocessing else {
            return nil
        }
        return cache.mediumImageData(for: owner)
    }

    var hasEncrypted: Bool {
        switch type {
        case .file:
            cache.hasEncryptedFileData(for: owner)
        case .image, .thumbnail:
            cache.hasEncryptedMediumImageData(for: owner)
        }
    }

    var encrypted: Data? {
        switch type {
        case .file:
            cache.encryptedFileData(for: owner)
        case .image, .thumbnail:
            cache.encryptedMediumImageData(for: owner)
        }
    }

    var isUploaded: Bool {
        guard let genericMessage = owner.underlyingMessage else {
            return false
        }

        switch type {
        case .thumbnail:
            return genericMessage.assetData?.preview.remote.hasAssetID ?? false
        case .file, .image:
            return genericMessage.assetData?.uploaded.hasAssetID ?? false
        }
    }

    func updateWithAssetId(
        _ assetId: String,
        token: String?,
        domain: String?
    ) {
        guard var genericMessage = owner.underlyingMessage else {
            return
        }

        switch type {
        case .thumbnail:
            genericMessage.updatePreview(
                assetId: assetId,
                token: token,
                domain: domain
            )

        case .file, .image:
            genericMessage.updateUploaded(
                assetId: assetId,
                token: token,
                domain: domain
            )
        }

        do {
            try owner.mergeWithExistingData(message: genericMessage)
        } catch {
            WireLogger.messageProcessing.warn(
                "Failed to update asset id. Reason: \(error.localizedDescription)",
                attributes: [.nonce: genericMessage.messageID.redactedAndTruncated()]
            )
            return
        }
    }

    func updateWithPreprocessedData(
        _ preprocessedImageData: Data,
        imageProperties: ZMIImageProperties
    ) {
        guard
            needsPreprocessing,
            var genericMessage = owner.underlyingMessage
        else {
            return
        }

        // Now we have the preprocessed data, delete the original.
        cache.storeMediumImage(data: preprocessedImageData, for: owner)
        cache.deleteOriginalImageData(for: owner)

        switch type {
        case .file:
            return
        case .image:
            genericMessage.updateAssetOriginal(withImageProperties: imageProperties)
        case .thumbnail:
            genericMessage.updateAssetPreview(withImageProperties: imageProperties)
        }

        do {
            try owner.setUnderlyingMessage(genericMessage)
        } catch {
            Logging.messageProcessing
                .warn("Failed to update preprocessed image data. Reason: \(error.localizedDescription)")
        }
    }

    func encrypt() {
        guard var genericMessage = owner.underlyingMessage else {
            return
        }

        switch type {
        case .file:
            WireLogger.assets.debug(
                "encrypting file",
                attributes: [.nonce: genericMessage.messageID.redactedAndTruncated()]
            )
            if let keys = cache.encryptFileAndComputeSHA256Digest(owner) {
                genericMessage.updateAsset(withUploadedOTRKey: keys.otrKey, sha256: keys.sha256!)
                WireLogger.assets.debug(
                    "encrypted file",
                    attributes: [.nonce: genericMessage.messageID.redactedAndTruncated()]
                )
            }

        case .image:
            if !needsPreprocessing, let original {
                // Even if we don't do any preprocessing on an image we still need to copy it to .medium
                cache.storeMediumImage(data: original, for: owner)
            }

            WireLogger.assets.debug(
                "encrypting image",
                attributes: [.nonce: genericMessage.messageID.redactedAndTruncated()]
            )
            if let keys = cache.encryptImageAndComputeSHA256Digest(owner, format: .medium) {
                genericMessage.updateAsset(withUploadedOTRKey: keys.otrKey, sha256: keys.sha256!)
                WireLogger.assets.debug(
                    "encrypted image",
                    attributes: [.nonce: genericMessage.messageID.redactedAndTruncated()]
                )
            }

        case .thumbnail:
            WireLogger.assets.debug(
                "encrypting thumbnail",
                attributes: [.nonce: genericMessage.messageID.redactedAndTruncated()]
            )
            if let keys = cache.encryptImageAndComputeSHA256Digest(owner, format: .medium) {
                genericMessage.updateAssetPreview(withUploadedOTRKey: keys.otrKey, sha256: keys.sha256!)
                WireLogger.assets.debug(
                    "encrypted thumbnail",
                    attributes: [.nonce: genericMessage.messageID.redactedAndTruncated()]
                )
            }
        }

        do {
            try owner.setUnderlyingMessage(genericMessage)
        } catch {
            WireLogger.messageProcessing.warn(
                "Failed to encrypt asset message data. Reason: \(error.localizedDescription)",
                attributes: [.nonce: genericMessage.messageID.redactedAndTruncated()]
            )
        }
    }
}

// MARK: - ZMAssetClientMessage + AssetMessage

extension ZMAssetClientMessage: AssetMessage {
    public var assets: [AssetType] {
        guard let cache = managedObjectContext?.zm_fileAssetCache else {
            return []
        }

        var assets = [AssetType]()

        if isFile {
            if cache.hasFileData(for: self) {
                assets.append(CacheAsset(owner: self, type: .file, cache: cache))
            }

            if cache.hasImageData(for: self) {
                assets.append(CacheAsset(owner: self, type: .thumbnail, cache: cache))
            }
        } else if cache.hasImageData(for: self) {
            assets.append(CacheAsset(owner: self, type: .image, cache: cache))
        }

        return assets
    }

    public var processingState: AssetProcessingState {
        let assets = assets

        // There is an asset that still needs encrypting and uploading.
        if assets.contains(where: {
            !$0.isUploaded && !$0.hasEncrypted
        }) {
            return .preprocessing
        }

        // There is some asset that isn't uploaded.
        if assets.contains(where: {
            !$0.isUploaded
        }) {
            return .uploading
        }

        return .done
    }
}

// MARK: - AssetMessage

/// Exposes all the assets which are contained within a message
public protocol AssetMessage {
    /// List of assets which the message contains.
    ///
    /// NOTE: The order of this list needs to be stable.
    var assets: [AssetType] { get }

    /// Summary of the processing state for the assets
    var processingState: AssetProcessingState { get }
}

// MARK: - AssetType

/// Represent a single asset like file, thumbnail, image and image preview.
/// rename to AssetType to prevent build error due to name conflict with Proto.Asset struct
public protocol AssetType {
    /// True if the original unprocessed data is available on disk
    var hasOriginal: Bool { get }

    /// Original unprocessed data
    var original: Data? { get }

    /// True if this asset needs image processing
    var needsPreprocessing: Bool { get }

    /// If the preprocessed data is available on disk
    var hasPreprocessed: Bool { get }

    // Preprocessed data
    var preprocessed: Data? { get }

    /// True if the encrypted data is available on disk
    var hasEncrypted: Bool { get }

    /// Encrypted data
    var encrypted: Data? { get }

    /// True if the encrypted data has been uploaded to the backend
    var isUploaded: Bool { get }

    /// Update the asset with the asset id and token received from the backend
    func updateWithAssetId(_ assetId: String, token: String?, domain: String?)

    /// Update the asset with preprocessed image data
    func updateWithPreprocessedData(_ preprocessedImageData: Data, imageProperties: ZMIImageProperties)

    /// Encrypt the original or preprocessed data
    func encrypt()
}
