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

// MARK: - UserProfileImageUpdateError

enum UserProfileImageUpdateError: Error {
    case preprocessingFailed
    case uploadFailed(Error)
}

// MARK: - UserProfileImageUpdateStateDelegate

protocol UserProfileImageUpdateStateDelegate: AnyObject {
    func failed(withError: UserProfileImageUpdateError)
}

// MARK: - UserProfileImageUploadStatusProtocol

protocol UserProfileImageUploadStatusProtocol: AnyObject {
    func hasAssetToDelete() -> Bool
    func consumeAssetToDelete() -> String?
    func consumeImage(for size: ProfileImageSize) -> Data?
    func hasImageToUpload(for size: ProfileImageSize) -> Bool
    func uploadingDone(imageSize: ProfileImageSize, assetId: String)
    func uploadingFailed(imageSize: ProfileImageSize, error: Error)
}

// MARK: - UserProfileImageUpdateProtocol

@objc
public protocol UserProfileImageUpdateProtocol: AnyObject {
    @objc(updateImageWithImageData:)
    func updateImage(imageData: Data)
}

// MARK: - UserProfileImageUploadStateChangeDelegate

protocol UserProfileImageUploadStateChangeDelegate: AnyObject {
    func didTransition(
        from oldState: UserProfileImageUpdateStatus.ProfileUpdateState,
        to currentState: UserProfileImageUpdateStatus.ProfileUpdateState
    )
    func didTransition(
        from oldState: UserProfileImageUpdateStatus.ImageState,
        to currentState: UserProfileImageUpdateStatus.ImageState,
        for size: ProfileImageSize
    )
}

// MARK: - UserProfileImageUpdateStatus

public final class UserProfileImageUpdateStatus: NSObject {
    // MARK: Lifecycle

    public convenience init(managedObjectContext: NSManagedObjectContext) {
        self.init(
            managedObjectContext: managedObjectContext,
            preprocessor: ZMAssetsPreprocessor(delegate: nil),
            queue: ZMImagePreprocessor.createSuitableImagePreprocessingQueue(),
            delegate: nil
        )
    }

    init(
        managedObjectContext: NSManagedObjectContext,
        preprocessor: ZMAssetsPreprocessorProtocol,
        queue: OperationQueue,
        delegate: UserProfileImageUploadStateChangeDelegate?
    ) {
        log.debug("Created")
        self.queue = queue
        self.preprocessor = preprocessor
        self.syncMOC = managedObjectContext
        self.changeDelegate = delegate
        super.init()
        self.preprocessor?.delegate = self
    }

    // MARK: Internal

    enum ImageState {
        case ready
        case preprocessing
        case upload(image: Data)
        case uploading
        case uploaded(assetId: String)
        case failed(UserProfileImageUpdateError)

        // MARK: Internal

        func canTransition(to newState: ImageState) -> Bool {
            switch (self, newState) {
            case (.ready, .preprocessing),
                 (.preprocessing, .upload),
                 (.upload, .uploading),
                 (.uploading, .uploaded),
                 (.ready, .upload): // When re-uploading a preprocessed v2 to v3
                true

            case (.uploaded, .ready),
                 (.failed, .ready):
                true

            case (.failed, .failed):
                false

            case (_, .failed):
                true

            default:
                false
            }
        }
    }

    enum ProfileUpdateState {
        case ready
        case preprocess(image: Data)
        case update(previewAssetId: String, completeAssetId: String)
        case failed(UserProfileImageUpdateError)

        // MARK: Internal

        func canTransition(to newState: ProfileUpdateState) -> Bool {
            switch (self, newState) {
            case (.ready, .preprocess),
                 (.preprocess, .update),
                 (.ready, .update): // When re-uploading a preprocessed v2 to v3
                true

            case (.update, .ready),
                 (.failed, .ready):
                true

            case (.failed, .failed):
                false

            case (_, .failed):
                true

            default:
                false
            }
        }
    }

    var preprocessor: ZMAssetsPreprocessorProtocol?
    let queue: OperationQueue
    weak var changeDelegate: UserProfileImageUploadStateChangeDelegate?

    fileprivate(set) var state: ProfileUpdateState = .ready
    fileprivate(set) var assetsToDelete = Set<String>()

    // MARK: Fileprivate

    fileprivate var log = ZMSLog(tag: "UserProfileImageUpdateStatus")

    fileprivate var changeDelegates: [UserProfileImageUpdateStateDelegate] = []
    fileprivate var imageOwner: ImageOwner?
    fileprivate let syncMOC: NSManagedObjectContext

    fileprivate var imageState = [ProfileImageSize: ImageState]()
    fileprivate var resizedImages = [ProfileImageSize: Data]()
}

// MARK: Main state transitions

extension UserProfileImageUpdateStatus {
    func setState(state newState: ProfileUpdateState) {
        let currentState = state
        guard currentState.canTransition(to: newState) else {
            log.debug("Invalid transition: [\(currentState)] -> [\(newState)], ignoring")
            // Trying to transition to invalid state - ignore
            return
        }
        state = newState
        didTransition(from: currentState, to: newState)
    }

    private func didTransition(from oldState: ProfileUpdateState, to currentState: ProfileUpdateState) {
        log.debug("Transition: [\(oldState)] -> [\(currentState)]")
        changeDelegate?.didTransition(from: oldState, to: currentState)
        switch (oldState, currentState) {
        case (_, .ready):
            resetImageState()
        case let (_, .preprocess(image: data)):
            startPreprocessing(imageData: data)
        case let (_, .update(previewAssetId: previewAssetId, completeAssetId: completeAssetId)):
            updateUserProfile(with: previewAssetId, completeAssetId: completeAssetId)
        case (_, .failed):
            resetImageState()
            setState(state: .ready)
        }
    }

    private func updateUserProfile(with previewAssetId: String, completeAssetId: String) {
        let selfUser = ZMUser.selfUser(in: syncMOC)
        assetsToDelete
            .formUnion(
                [selfUser.previewProfileAssetIdentifier, selfUser.completeProfileAssetIdentifier]
                    .compactMap { $0 }
            )
        selfUser.updateAndSyncProfileAssetIdentifiers(
            previewIdentifier: previewAssetId,
            completeIdentifier: completeAssetId
        )
        selfUser.setImage(data: resizedImages[.preview], size: .preview)
        selfUser.setImage(data: resizedImages[.complete], size: .complete)
        resetImageState()
        syncMOC.saveOrRollback()
        setState(state: .ready)
    }

    private func startPreprocessing(imageData: Data) {
        for siz in ProfileImageSize.allSizes {
            setState(state: .preprocessing, for: siz)
        }

        let imageOwner = UserProfileImageOwner(imageData: imageData)
        guard let operations = preprocessor?.operations(forPreprocessingImageOwner: imageOwner),
              !operations.isEmpty else {
            resetImageState()
            setState(state: .failed(.preprocessingFailed))
            return
        }

        queue.addOperations(operations, waitUntilFinished: false)
    }
}

// MARK: Image state transitions

extension UserProfileImageUpdateStatus {
    func imageState(for imageSize: ProfileImageSize) -> ImageState {
        imageState[imageSize] ?? .ready
    }

    func setState(state newState: ImageState, for imageSize: ProfileImageSize) {
        let currentState = imageState(for: imageSize)
        guard currentState.canTransition(to: newState) else {
            // Trying to transition to invalid state - ignore
            return
        }

        imageState[imageSize] = newState
        didTransition(from: currentState, to: newState, for: imageSize)
    }

    func resetImageState() {
        imageState.removeAll()
        resizedImages.removeAll()
    }

    private func didTransition(from oldState: ImageState, to currentState: ImageState, for size: ProfileImageSize) {
        log.debug("Transition [\(size)]: [\(oldState)] -> [\(currentState)]")
        changeDelegate?.didTransition(from: oldState, to: currentState, for: size)
        switch (oldState, currentState) {
        case let (_, .upload(image)):
            resizedImages[size] = image
            RequestAvailableNotification.notifyNewRequestsAvailable(self)

        case (_, .uploaded):
            // When one image is uploaded we check state of all other images
            let previewState = imageState(for: .preview)
            let completeState = imageState(for: .complete)

            switch (previewState, completeState) {
            case let (.uploaded(assetId: previewAssetId), .uploaded(assetId: completeAssetId)):
                // If both images are uploaded we can update profile
                setState(state: .update(previewAssetId: previewAssetId, completeAssetId: completeAssetId))
            default:
                break // Need to wait until both images are uploaded
            }

        case let (_, .failed(error)):
            setState(state: .failed(error))

        default:
            break
        }
    }
}

// MARK: UserProfileImageUpdateProtocol

// Called from the UI to update a v3 image
extension UserProfileImageUpdateStatus: UserProfileImageUpdateProtocol {
    /// Starts the process of updating profile picture.
    ///
    /// - Important: Expected to be run from UI thread
    ///
    /// - Parameter imageData: image data of the new profile picture
    public func updateImage(imageData: Data) {
        syncMOC.performGroupedBlock {
            self.setState(state: .preprocess(image: imageData))
        }
    }
}

// MARK: ZMAssetsPreprocessorDelegate

extension UserProfileImageUpdateStatus: ZMAssetsPreprocessorDelegate {
    public func completedDownsampleOperation(
        _ operation: ZMImageDownsampleOperationProtocol,
        imageOwner: ZMImageOwner
    ) {
        syncMOC.performGroupedBlock {
            for siz in ProfileImageSize.allSizes {
                if operation.format == siz.imageFormat,
                   let downsampleImageData = operation.downsampleImageData {
                    self.setState(state: .upload(image: downsampleImageData), for: siz)
                }
            }
        }
    }

    public func failedPreprocessingImageOwner(_: ZMImageOwner) {
        syncMOC.performGroupedBlock {
            self.setState(state: .failed(.preprocessingFailed))
        }
    }

    public func preprocessingCompleteOperation(for imageOwner: ZMImageOwner) -> Operation? {
        let dispatchGroup = syncMOC.dispatchGroup
        dispatchGroup?.enter()
        return BlockOperation {
            dispatchGroup?.leave()
        }
    }
}

// MARK: UserProfileImageUploadStatusProtocol

extension UserProfileImageUpdateStatus: UserProfileImageUploadStatusProtocol {
    /// Checks if there are assets that needs to be deleted
    ///
    /// - Returns: true if there are assets that needs to be deleted
    func hasAssetToDelete() -> Bool {
        !assetsToDelete.isEmpty
    }

    /// Takes an asset ID that needs to be deleted and removes from the internal list
    ///
    /// - Returns: Asset ID or nil if nothing needs to be deleted
    func consumeAssetToDelete() -> String? {
        assetsToDelete.removeFirst()
    }

    /// Checks if there is an image to upload
    ///
    /// - Important: should be called from sync thread
    /// - Parameter size: which image size to check
    /// - Returns: true if there is an image of this size ready for upload
    func hasImageToUpload(for size: ProfileImageSize) -> Bool {
        switch imageState(for: size) {
        case .upload:
            true
        default:
            false
        }
    }

    /// Takes an image that is ready for upload and marks it internally
    /// as currently being uploaded.
    ///
    /// - Parameter size: size of the image
    /// - Returns: Image data if there is image of this size ready for upload
    func consumeImage(for size: ProfileImageSize) -> Data? {
        switch imageState(for: size) {
        case let .upload(image: image):
            setState(state: .uploading, for: size)
            return image

        default:
            return nil
        }
    }

    /// Marks the image as uploaded successfully
    ///
    /// - Parameters:
    ///   - imageSize: size of the image
    ///   - assetId: resulting asset identifier after uploading it to the store
    func uploadingDone(imageSize: ProfileImageSize, assetId: String) {
        setState(state: .uploaded(assetId: assetId), for: imageSize)
    }

    /// Marks the image as failed to upload
    ///
    /// - Parameters:
    ///   - imageSize: size of the image
    ///   - error: transport error
    func uploadingFailed(imageSize: ProfileImageSize, error: Error) {
        setState(state: .failed(.uploadFailed(error)), for: imageSize)
    }
}
