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

import AVFoundation
import ImageIO
import MobileCoreServices
import UIKit
import WireCommonComponents
import WireDataModel
import WireShareEngine

// MARK: - UnsentSendableError

/// Error that can happen during the preparation or sending operation
enum UnsentSendableError: Error {
    // The attachment is not supported to be sent, this can currently be the case if the user sends a URL
    // which does not contain a File, e.g. an URL to a webpage, which instead will also be included in the text content.
    // `UnsentSendables` that report this error should not be sent.
    case unsupportedAttachment

    // The attachment is over file size limitation
    case fileSizeTooBig

    // the target conversation does not exist anymore
    case conversationDoesNotExist
}

// MARK: LocalizedError

extension UnsentSendableError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .fileSizeTooBig:

            let maxSizeString = ByteCountFormatter.string(
                fromByteCount: Int64(AccountManager.fileSizeLimitInBytes),
                countStyle: .binary
            )

            return L10n.ShareExtension.Content.File.tooBig(maxSizeString)

        case .unsupportedAttachment:
            return L10n.ShareExtension.Content.File.unsupportedAttachment

        case .conversationDoesNotExist:
            return L10n.ShareExtension.Error.ConversationDoesNotExist.message
        }
    }
}

// MARK: - UnsentSendable

/// This protocol defines the basic methods that an Object needes to conform to
/// in order to be prepared and sent. A consumer should ask the objects if they need to perform
/// perparation operations and call `prepare` before calling `send`.
protocol UnsentSendable {
    func prepare(completion: @escaping () -> Void)
    func send(completion: @escaping (Sendable?) -> Void)

    var needsPreparation: Bool { get }
    var error: UnsentSendableError? { get }
}

extension UnsentSendable {
    func prepare(completion: @escaping () -> Void) {
        precondition(needsPreparation, "Ensure this objects needs preparation, c.f. `needsPreparation`")
    }
}

// MARK: - UnsentSendableBase

class UnsentSendableBase {
    let conversation: WireShareEngine.Conversation
    let sharingSession: SharingSession

    var needsPreparation = false

    var error: UnsentSendableError?

    init(conversation: WireShareEngine.Conversation, sharingSession: SharingSession) {
        self.conversation = conversation
        self.sharingSession = sharingSession
    }
}

// MARK: - UnsentTextSendable

/// `UnsentSendable` implementation to send text messages
final class UnsentTextSendable: UnsentSendableBase, UnsentSendable {
    private var text: String
    private let attachment: NSItemProvider?

    init(
        conversation: WireShareEngine.Conversation,
        sharingSession: SharingSession,
        text: String,
        attachment: NSItemProvider? = nil
    ) {
        self.text = text
        self.attachment = attachment
        super.init(conversation: conversation, sharingSession: sharingSession)
        if attachment != nil {
            needsPreparation = true
        }
    }

    func send(completion: @escaping (Sendable?) -> Void) {
        sharingSession.enqueue { [weak self] in
            guard let self else { return }
            let fetchPreview = !ExtensionSettings.shared.disableLinkPreviews
            let message = conversation.appendTextMessage(text, fetchLinkPreview: fetchPreview)
            completion(message)
        }
    }

    func prepare(completion: @escaping () -> Void) {
        precondition(needsPreparation, "Ensure this objects needs preparation, c.f. `needsPreparation`")
        needsPreparation = false

        if let attachment, attachment.hasURL {
            self.attachment?.fetchURL(completion: { _ in
                completion()
            })
        } else {
            completion()
        }
    }
}

// MARK: - UnsentImageSendable

/// `UnsentSendable` implementation to send image messages
final class UnsentImageSendable: UnsentSendableBase, UnsentSendable {
    private let attachment: NSItemProvider
    private var imageData: Data?

    init?(conversation: WireShareEngine.Conversation, sharingSession: SharingSession, attachment: NSItemProvider) {
        guard attachment.hasItemConformingToTypeIdentifier(UTType.image.identifier) else { return nil }
        self.attachment = attachment
        super.init(conversation: conversation, sharingSession: sharingSession)
        needsPreparation = true
    }

    func prepare(completion: @escaping () -> Void) {
        precondition(needsPreparation, "Ensure this objects needs preparation, c.f. `needsPreparation`")
        needsPreparation = false

        let longestDimension: CGFloat = 1024

        // note: this doesn't seem to have any effect, but perhaps it's an iOS bug that will be fixed...
        let options = [NSItemProviderPreferredImageSizeKey: NSValue(cgSize: CGSize(
            width: longestDimension,
            height: longestDimension
        ))]

        // app extensions have severely limited memory resources & risk termination if they are too greedy. In order to
        // minimize memory consumption we must downscale the images being shared. Standard image scaling methods that
        // rely on UIImage are too expensive (eg. 12MP image -> approx 48MB UIImage), so we make the system scale the
        // images
        // for us ('free' of charge) by using the image URL & ImageIO library.
        //

        attachment.loadItem(forTypeIdentifier: UTType.image.identifier, options: options) { [weak self] url, error in
            error?.log(message: "Unable to load image from attachment")

            // Tries to load the content from local URL...

            if let cfUrl = (url as? URL) as CFURL?,
               let imageSource = CGImageSourceCreateWithURL(cfUrl, nil) {
                let options: [NSString: Any] = [
                    kCGImageSourceThumbnailMaxPixelSize: longestDimension,
                    kCGImageSourceCreateThumbnailFromImageAlways: true,
                    kCGImageSourceCreateThumbnailWithTransform: true,
                ]

                if let scaledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) {
                    self?.imageData = UIImage(cgImage: scaledImage).jpegData(compressionQuality: 0.9)
                }

                completion()

            } else {
                // if it fails, it will attach the content directly

                self?.attachment
                    .loadItem(
                        forTypeIdentifier: UTType.image.identifier,
                        options: options
                    ) { [weak self] image, error in

                        error?.log(message: "Unable to load image from attachment")

                        if let image = image as? UIImage {
                            self?.imageData = image.jpegData(compressionQuality: 0.9)
                        }

                        completion()
                    }
            }
        }
    }

    func send(completion: @escaping (Sendable?) -> Void) {
        sharingSession.enqueue { [weak self] in
            guard let self else { return }
            completion(imageData.flatMap(conversation.appendImage))
        }
    }
}

// MARK: - UnsentFileSendable

/// `UnsentSendable` implementation to send file messages
class UnsentFileSendable: UnsentSendableBase, UnsentSendable {
    static let passkitUTI = "com.apple.pkpass"
    private let attachment: NSItemProvider
    private var metadata: ZMFileMetadata?

    private let typeURL: Bool
    private let typeData: Bool
    private let typePass: Bool

    private let fileMetaDataGenerator = FileMetaDataGenerator()

    init?(conversation: WireShareEngine.Conversation, sharingSession: SharingSession, attachment: NSItemProvider) {
        self.typeURL = attachment.hasItemConformingToTypeIdentifier(UTType.url.identifier)
        self.typeData = attachment.hasItemConformingToTypeIdentifier(UTType.data.identifier)
        self.typePass = attachment.hasItemConformingToTypeIdentifier(UnsentFileSendable.passkitUTI)
        self.attachment = attachment
        super.init(conversation: conversation, sharingSession: sharingSession)
        guard typeURL || typeData || typePass else { return nil }
        needsPreparation = true
    }

    func prepare(completion: @escaping () -> Void) {
        precondition(needsPreparation, "Ensure this objects needs preparation, c.f. `needsPreparation`")
        needsPreparation = false

        if typeURL {
            attachment.fetchURL { [weak self] url in
                guard let self else { return }
                if (url != nil && !url!.isFileURL) || !typeData {
                    error = .unsupportedAttachment
                    return completion()
                }

                prepareAsFileData(name: url?.lastPathComponent, completion: completion)
            }
        } else if typePass {
            prepareAsWalletPass(name: nil, completion: completion)
        } else if typeData {
            prepareAsFileData(name: nil, completion: completion)
        }
    }

    func send(completion: @escaping (Sendable?) -> Void) {
        sharingSession.enqueue { [weak self] in
            guard let self else { return }
            completion(metadata.flatMap(conversation.appendFile))
        }
    }

    private func prepareAsFileData(name: String?, completion: @escaping () -> Void) {
        prepareAsFile(name: name, typeIdentifier: UTType.data.identifier, completion: completion)
    }

    private func prepareAsWalletPass(name: String?, completion: @escaping () -> Void) {
        prepareAsFile(name: nil, typeIdentifier: UnsentFileSendable.passkitUTI, completion: completion)
    }

    private func prepareAsFile(name: String?, typeIdentifier: String, completion: @escaping () -> Void) {
        attachment.loadItem(forTypeIdentifier: typeIdentifier, options: [:]) { [weak self] data, error in
            guard let UTIString = self?.attachment.registeredTypeIdentifiers.first, error == nil else {
                error?.log(message: "Unable to load file from attachment")
                return completion()
            }

            let prepareColsure: SendingCompletion = { url, error in
                guard let url, error == nil else {
                    error?.log(message: "Unable to prepare file attachment for sending")
                    return completion()
                }

                // Generating PDF previews can be expensive. To avoid hitting the Share Extension's
                // memory budget we should avoid to generate previews if the file is a PDF.
                guard let type = UTType(url.UTI()), type.conforms(to: UTType.pdf) else {
                    self?.metadata = ZMFileMetadata(fileURL: url)
                    completion()
                    return
                }

                // Generate preview
                self?.fileMetaDataGenerator.metadataForFileAtURL(
                    url,
                    UTI: url.UTI(),
                    name: name ?? url.lastPathComponent
                ) { [weak self] metadata in
                    self?.metadata = metadata
                    completion()
                }
            }

            if let data = data as? Data {
                guard data.count <= AccountManager.fileSizeLimitInBytes else {
                    self?.error = .fileSizeTooBig
                    return completion()
                }

                self?.prepareForSending(
                    withUTI: UTIString,
                    name: name,
                    data: data,
                    completion: prepareColsure
                )
            } else if let dataURL = data as? URL {
                guard dataURL.fileSize ?? .max <= AccountManager.fileSizeLimitInBytes else {
                    self?.error = .fileSizeTooBig
                    return completion()
                }

                self?.prepareForSending(
                    withUTI: UTIString,
                    name: name,
                    dataURL: dataURL,
                    completion: prepareColsure
                )
            } else {
                completion()
            }
        }
    }

    typealias SendingCompletion = (URL?, Error?) -> Void

    private func convertVideoIfNeeded(
        UTI: String,
        fileURL: URL,
        completion: @escaping SendingCompletion
    ) {
        if UTType(UTI)?.conforms(to: UTType.movie) ?? false {
            AVURLAsset.convertVideoToUploadFormat(at: fileURL) { url, _, error in
                completion(url, error)
            }
        } else {
            completion(fileURL, nil)
        }
    }

    /// Process data URL to the right format to be sent
    /// - Parameters:
    ///   - UTI: UTI of the file to send
    ///   - name: file name
    ///   - dataURL: data URL
    ///   - completion: completion handler
    private func prepareForSending(
        withUTI UTI: String,
        name: String?,
        dataURL: URL,
        completion: @escaping SendingCompletion
    ) {
        guard let fileName = nameForFile(withUTI: UTI, name: name) else { return completion(nil, nil) }

        do {
            let tmp = try FileManager.createTmpDirectory()

            let tempFileURL = tmp.appendingPathComponent(fileName)

            do {
                try FileManager.default.removeTmpIfNeededAndCopy(fileURL: dataURL, tmpURL: tempFileURL)
            } catch {
                error.log(message: "Cannot copy video from \(dataURL) to \(tempFileURL): \(error)")
                return
            }

            convertVideoIfNeeded(UTI: UTI, fileURL: tempFileURL, completion: completion)
        } catch {
            return completion(nil, error)
        }
    }

    /// Process data to the right format to be sent
    private func prepareForSending(
        withUTI UTI: String,
        name: String?,
        data: Data,
        completion: @escaping (URL?, Error?) -> Void
    ) {
        guard let fileName = nameForFile(withUTI: UTI, name: name) else { return completion(nil, nil) }

        let fileManager = FileManager.default

        do {
            let tmp = try FileManager.createTmpDirectory()

            let tempFileURL = tmp.appendingPathComponent(fileName)

            if fileManager.fileExists(atPath: tempFileURL.absoluteString) {
                try fileManager.removeItem(at: tempFileURL)
            }

            try data.write(to: tempFileURL)

            convertVideoIfNeeded(UTI: UTI, fileURL: tempFileURL, completion: completion)
        } catch {
            return completion(nil, error)
        }
    }

    private func nameForFile(withUTI UTI: String, name: String?) -> String? {
        if let fileExtension = UTType(UTI)?.preferredFilenameExtension {
            return "\(UUID().uuidString).\(fileExtension)"
        }
        return name
    }
}

extension AccountManager {
    // MARK: - Host App State

    static var sharedAccountManager: AccountManager? {
        guard let applicationGroupIdentifier = Bundle.main.applicationGroupIdentifier else { return nil }
        let sharedContainerURL = FileManager.sharedContainerDirectory(for: applicationGroupIdentifier)
        return AccountManager(sharedDirectory: sharedContainerURL)
    }

    static var fileSizeLimitInBytes: UInt64 {
        UInt64.uploadFileSizeLimit(hasTeam: AccountManager.sharedAccountManager?.selectedAccount?.teamName != nil)
    }
}
