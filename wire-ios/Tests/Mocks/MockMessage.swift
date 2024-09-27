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
import WireLinkPreview
import XCTest

// MARK: - MockCompositeMessageData

final class MockCompositeMessageData: NSObject, CompositeMessageData {
    var items: [CompositeMessageItem] = []
}

// MARK: - MockTextMessageData

final class MockTextMessageData: NSObject, TextMessageData {
    var messageText: String? = ""
    var backingLinkPreview: LinkMetadata?
    var imageData: Data?
    var linkPreviewHasImage = false
    var linkPreviewImageCacheKey: String?
    var mentions = [Mention]()

    var quote: ZMMessage? {
        get {
            XCTFail("This property should not be used in tests")
            return nil
        }

        set {
            XCTFail("This property should not be used in tests")
        }
    }

    var quoteMessage: ZMConversationMessage?
    var isQuotingSelf = false
    var hasQuote = false

    var linkPreview: LinkMetadata? {
        guard let linkPreview = backingLinkPreview, !linkPreview.isBlacklisted else { return nil }
        return linkPreview
    }

    func fetchLinkPreviewImageData(queue: DispatchQueue, completionHandler: @escaping ((Data?) -> Void)) {
        completionHandler(imageData)
    }

    func requestLinkPreviewImageDownload() {
        // no-op
    }

    func editText(_ text: String, mentions: [Mention], fetchLinkPreview: Bool) {
        // stub
    }
}

// MARK: - MockSystemMessageData

final class MockSystemMessageData: NSObject, ZMSystemMessageData {
    var messageTimer: NSNumber?
    var systemMessageType: ZMSystemMessageType = .invalid
    var users: Set<ZMUser> {
        get {
            XCTFail("This property should not be used in tests")
            return Set()
        }

        set {
            XCTFail("This property should not be used in tests")
        }
    }

    var userTypes: Set<AnyHashable> = Set()
    var clients: Set<AnyHashable> = Set()
    var addedUsers: Set<ZMUser> {
        get {
            XCTFail("This property should not be used in tests")
            return Set()
        }

        set {
            XCTFail("This property should not be used in tests")
        }
    }

    var addedUserTypes: Set<AnyHashable> = Set()
    var removedUsers: Set<ZMUser> {
        get {
            XCTFail("This property should not be used in tests")
            return Set()
        }

        set {
            XCTFail("This property should not be used in tests")
        }
    }

    var removedUserTypes: Set<AnyHashable> = Set()
    var text: String? = ""
    var needsUpdatingUsers = false
    var userIsTheSender = false
    var decryptionErrorCode: NSNumber?
    var isDecryptionErrorRecoverable = true
    var senderClientID: String? = "452367891023123"

    var duration: TimeInterval = 0
    var childMessages = Set<AnyHashable>()
    var parentMessage: ZMSystemMessageData?
    var participantsRemovedReason: ZMParticipantsRemovedReason
    var domains: [String]?

    init(systemMessageType: ZMSystemMessageType, reason: ZMParticipantsRemovedReason, domains: [String]? = nil) {
        self.systemMessageType = systemMessageType
        self.participantsRemovedReason = reason
        self.domains = domains
    }
}

// MARK: - MockFileMessageDataType

protocol MockFileMessageDataType: ZMFileMessageData {
    var size: UInt64 { get set }
    var mimeType: String? { get set }
    var filename: String? { get set }
    var fileURL: URL? { get set }
    var previewData: Data? { get set }
    var durationMilliseconds: UInt64 { get set }
    var normalizedLoudness: [Float]? { get set }
    var transferState: AssetTransferState { get set }
    var downloadState: AssetDownloadState { get set }
}

// MARK: - MockPassFileMessageData + MockFileMessageDataType

extension MockPassFileMessageData: MockFileMessageDataType {}

// MARK: - MockFileMessageData + MockFileMessageDataType

extension MockFileMessageData: MockFileMessageDataType {}

// MARK: - MockPassFileMessageData

final class MockPassFileMessageData: NSObject, ZMFileMessageData {
    var mimeType: String? = "application/vnd.apple.pkpass"
    var size: UInt64 = 1024 * 1024 * 2
    var transferState: AssetTransferState = .uploaded
    var downloadState: AssetDownloadState = .remote
    var filename: String? = "ticket.pkpass"
    var progress: Float = 0
    var fileURL: URL? {
        get {
            let path = Bundle(for: type(of: self)).path(forResource: "sample", ofType: "pkpass")!
            return URL(fileURLWithPath: path)
        }

        set {}
    }

    var thumbnailAssetID: String? = ""
    var imagePreviewDataIdentifier: String? = "preview-identifier-123"
    var durationMilliseconds: UInt64 = 0
    var videoDimensions = CGSize.zero
    var normalizedLoudness: [Float]? = []
    var previewData: Data?

    var isPass: Bool {
        mimeType == "application/vnd.apple.pkpass"
    }

    var isVideo: Bool {
        mimeType == "video/mp4"
    }

    var isAudio: Bool {
        mimeType == "audio/x-m4a"
    }

    var isPDF: Bool {
        mimeType == "application/pdf"
    }

    var v3_isImage: Bool {
        false
    }

    var hasLocalFileData: Bool {
        fileURL != nil
    }

    func temporaryURLToDecryptedFile() -> URL? {
        fileURL
    }

    func requestFileDownload() {
        // no-op
    }

    func cancelTransfer() {
        // no-op
    }

    func fetchImagePreviewData(queue: DispatchQueue, completionHandler: @escaping (Data?) -> Void) {
        completionHandler(previewData)
    }

    func requestImagePreviewDownload() {
        // no-op
    }

    func signPDFDocument(observer: SignatureObserver) -> Any? {
        nil
    }

    func retrievePDFSignature() {
        // no-op
    }
}

// MARK: - MockFileMessageData

final class MockFileMessageData: NSObject, ZMFileMessageData {
    var mimeType: String? = "application/pdf"
    var size: UInt64 = 1024 * 1024 * 2
    var transferState: AssetTransferState = .uploaded
    var downloadState: AssetDownloadState = .remote
    var filename: String? = "TestFile.pdf"
    var progress: Float = 0
    var fileURL: URL? = .none
    var thumbnailAssetID: String? = ""
    var imagePreviewDataIdentifier: String? = "preview-identifier-123"
    var durationMilliseconds: UInt64 = 233_000
    var videoDimensions = CGSize.zero
    var normalizedLoudness: [Float]? = []
    var previewData: Data?

    var isPass: Bool {
        mimeType == "application/vnd.apple.pkpass"
    }

    var isVideo: Bool {
        mimeType == "video/mp4"
    }

    var isAudio: Bool {
        mimeType == "audio/x-m4a"
    }

    var isPDF: Bool {
        mimeType == "application/pdf"
    }

    var v3_isImage: Bool {
        false
    }

    var hasLocalFileData: Bool {
        fileURL != nil
    }

    func temporaryURLToDecryptedFile() -> URL? {
        fileURL
    }

    func requestFileDownload() {
        // no-op
    }

    func cancelTransfer() {
        // no-op
    }

    func fetchImagePreviewData(queue: DispatchQueue, completionHandler: @escaping (Data?) -> Void) {
        completionHandler(previewData)
    }

    func requestImagePreviewDownload() {
        // no-op
    }

    func signPDFDocument(observer: SignatureObserver) -> Any? {
        nil
    }

    func retrievePDFSignature() {
        // no-op
    }
}

// MARK: - MockKnockMessageData

final class MockKnockMessageData: NSObject, ZMKnockMessageData {}

// MARK: - MockImageMessageData

final class MockImageMessageData: NSObject, ZMImageMessageData {
    var mockOriginalSize: CGSize = .zero
    var mockImageData = Data()
    var mockImageDataIdentifier = String()

    var mediumData: Data! = Data()
    var previewData: Data! = Data()
    var imagePreviewDataIdentifier: String! = String()

    var isDownloaded = true
    var isAnimatedGIF = false
    var imageType: String? = String()

    var imageData: Data? { mockImageData }
    var imageDataIdentifier: String? { mockImageDataIdentifier }
    var originalSize: CGSize { mockOriginalSize }

    func fetchImageData(with queue: DispatchQueue, completionHandler: @escaping ((Data?) -> Void)) {
        completionHandler(imageData)
    }

    func requestFileDownload() {
        // no-op
    }
}

// MARK: - MockLocationMessageData

final class MockLocationMessageData: NSObject, LocationMessageData {
    var longitude: Float = 0
    var latitude: Float = 0
    var name: String?
    var zoomLevel: Int32 = 0
}

// MARK: - MockMessage

class MockMessage: NSObject, ZMConversationMessage, ConversationCompositeMessage, SwiftConversationMessage {
    // MARK: - ConversationCompositeMessage

    var compositeMessageData: CompositeMessageData?

    typealias UsersByReaction = [String: [UserType]]

    // MARK: - ZMConversationMessage

    var nonce: UUID? = UUID()
    var isEncrypted = false
    var isPlainText = true
    var sender: ZMUser? {
        get {
            XCTFail("This property should not be used in tests")

            return nil
        }

        set {
            XCTFail("This property should not be used in tests")
        }
    }

    var senderUser: UserType? {
        didSet {
            if senderUser is ZMUser {
                XCTFail("ZMUser should not created for tests")
            }
        }
    }

    var serverTimestamp: Date? = .none
    var updatedAt: Date? = .none

    var conversation: ZMConversation? = .none
    var conversationLike: ConversationLike? = .none

    var deliveryState: ZMDeliveryState = .delivered
    var failedToSendReason: MessageSendFailure? = .unknown
    var failedToSendUsers: [UserType] = []

    var imageMessageData: ZMImageMessageData? = .none
    var knockMessageData: ZMKnockMessageData? = .none

    var causedSecurityLevelDegradation = false
    var needsReadConfirmation = false
    let objectIdentifier: String = UUID().uuidString
    var linkAttachments: [LinkAttachment]?
    var needsLinkAttachmentsUpdate = false
    var isSilenced = false
    var backingIsRestricted = false
    var isRestricted: Bool {
        backingIsRestricted
    }

    var isSent: Bool {
        switch deliveryState {
        case .failedToSend, .pending, .invalid:
            false
        default:
            true
        }
    }

    var fileMessageData: ZMFileMessageData? {
        backingFileMessageData
    }

    var locationMessageData: LocationMessageData? {
        backingLocationMessageData
    }

    var textMessageData: TextMessageData? {
        backingTextMessageData
    }

    var systemMessageData: ZMSystemMessageData? {
        backingSystemMessageData
    }

    var replies: Set<ZMMessage> = Set()

    var usersReaction: [String: [UserType]] {
        backingUsersReaction
    }

    func reactionsSortedByCreationDate() -> [ReactionData] {
        backingSortedReactions
    }

    var reactionData: Set<ReactionData> {
        backingReactionData
    }

    var backingUsersReaction: UsersByReaction = [:]
    var backingSortedReactions: [ReactionData] = []
    var backingReactionData: Set<ReactionData> = []
    var backingTextMessageData: MockTextMessageData! = .none
    var backingFileMessageData: MockFileMessageDataType! = .none
    var backingLocationMessageData: MockLocationMessageData! = .none
    var backingSystemMessageData: MockSystemMessageData! = .none

    var isEphemeral = false
    var isObfuscated = false

    var deletionTimeout: TimeInterval = -1
    var destructionDate: Date?

    func startSelfDestructionIfNeeded() -> Bool {
        true
    }

    func resend() {
        // no-op
    }

    var canBeDeleted: Bool {
        systemMessageData == nil
    }

    func markAsUnread() {
        // no-op
    }

    var readReceipts: [ReadReceipt] = []

    var canBeMarkedUnread = true

    var hasBeenDeleted = false

    var systemMessageType = ZMSystemMessageType.invalid

    override required init() {}
}
