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
import Photos
import UIKit
import WireCommonComponents
import WireDesign
import WireReusableUIComponents
import WireSyncEngine

private let zmLog = ZMSLog(tag: "UI")

// MARK: - CameraKeyboardViewControllerDelegate

protocol CameraKeyboardViewControllerDelegate: AnyObject {
    func cameraKeyboardViewController(_ controller: CameraKeyboardViewController, didSelectVideo: URL, duration: TimeInterval)
    func cameraKeyboardViewController(_ controller: CameraKeyboardViewController,
                                      didSelectImageData: Data,
                                      isFromCamera: Bool,
                                      uti: String?)
    func cameraKeyboardViewControllerWantsToOpenFullScreenCamera(_ controller: CameraKeyboardViewController)
    func cameraKeyboardViewControllerWantsToOpenCameraRoll(_ controller: CameraKeyboardViewController)
}

// MARK: - CameraKeyboardViewController

final class CameraKeyboardViewController: UIViewController {

    // MARK: - Properties

    private var permissions: PhotoPermissionsController!
    private var lastLayoutSize = CGSize.zero
    private let collectionViewLayout = UICollectionViewFlowLayout()
    private let sideMargin: CGFloat = 14
    private var viewWasHidden: Bool = false
    private var callStateObserverToken: Any?
    private var goBackButtonRevealed: Bool = false {
        didSet {
            if goBackButtonRevealed {
                UIView.animate(withDuration: 0.35, animations: {
                    self.goBackButton.alpha = self.goBackButtonRevealed ? 1 : 0
                })
            } else {
                self.goBackButton.alpha = 0
            }
        }
    }

    private enum CameraKeyboardSection: UInt {
        case camera = 0, photos = 1
    }

    private let mediaSharingRestrictionsMananger = MediaShareRestrictionManager(
        sessionRestriction: ZMUserSession.shared()
    )

    let assetLibrary: AssetLibrary?
    let imageManagerType: ImageManagerProtocol.Type

    var collectionView: UICollectionView!
    let goBackButton = IconButton()
    let cameraRollButton = IconButton()

    weak var delegate: CameraKeyboardViewControllerDelegate?

    private lazy var activityIndicator = BlockingActivityIndicator(view: view)

    // MARK: - Init

    init(
        imageManagerType: ImageManagerProtocol.Type = PHImageManager.self,
        permissions: PhotoPermissionsController = PhotoPermissionsControllerStrategy()
    ) {
        self.imageManagerType = imageManagerType
        self.assetLibrary = SecurityFlags.cameraRoll.isEnabled ? AssetLibrary() : nil
        self.permissions = permissions
        super.init(nibName: nil, bundle: nil)
        self.assetLibrary?.delegate = self
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidBecomeActive(_:)),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )

        if let userSession = ZMUserSession.shared() {
            self.callStateObserverToken = WireCallCenterV3.addCallStateObserver(
                observer: self,
                userSession: userSession
            )
        }
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Override methods

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        createConstraints()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !self.lastLayoutSize.equalTo(self.view.bounds.size) {
            self.lastLayoutSize = self.view.bounds.size
            self.collectionViewLayout.invalidateLayout()
            self.collectionView.reloadData()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.collectionViewLayout.invalidateLayout()
        self.collectionView.reloadData()
        if self.viewWasHidden {
            self.assetLibrary?.refetchAssets()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // For right-to-left layout first cell is at the far right corner.
        // We need to scroll to it when initially showing controller and it seems there is no other way...
        DispatchQueue.main.async {
            self.scrollToCamera(animated: false)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.viewWasHidden = true
    }

    // MARK: - Notifications

    @objc
    private func applicationDidBecomeActive(_ notification: Notification!) {
        self.assetLibrary?.refetchAssets()
    }

    // MARK: - Setup UI

    private func setupViews() {
        self.createCollectionView()

        self.goBackButton.translatesAutoresizingMaskIntoConstraints = false
        self.goBackButton.backgroundColor = .black
        self.goBackButton.circular = true
        self.goBackButton.setIcon(.backArrow, size: .tiny, for: [])
        self.goBackButton.setIconColor(.white, for: [])
        self.goBackButton.accessibilityIdentifier = "goBackButton"
        self.goBackButton.addTarget(self, action: #selector(goBackPressed(_:)), for: .touchUpInside)
        self.goBackButton.applyRTLTransformIfNeeded()

        self.cameraRollButton.translatesAutoresizingMaskIntoConstraints = false
        self.cameraRollButton.backgroundColor = .black
        self.cameraRollButton.circular = true
        self.cameraRollButton.setIcon(.photo, size: .tiny, for: [])
        self.cameraRollButton.setIconColor(.white, for: [])
        self.cameraRollButton.accessibilityIdentifier = "cameraRollButton"
        self.cameraRollButton.addTarget(self, action: #selector(openCameraRollPressed(_:)), for: .touchUpInside)

        [self.collectionView, self.goBackButton, self.cameraRollButton].forEach(self.view.addSubview)
    }

    private func createConstraints() {
        [
            collectionView,
            goBackButton,
            cameraRollButton
        ].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            goBackButton.widthAnchor.constraint(equalToConstant: 36),
            goBackButton.widthAnchor.constraint(equalTo: goBackButton.heightAnchor),

            goBackButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: sideMargin),
            goBackButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -38),

            cameraRollButton.widthAnchor.constraint(equalToConstant: 36),
            cameraRollButton.heightAnchor.constraint(equalToConstant: 36),
            cameraRollButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -sideMargin),
            cameraRollButton.bottomAnchor.constraint(equalTo: goBackButton.bottomAnchor)
        ])
    }

    private func createCollectionView() {
        self.collectionViewLayout.scrollDirection = .horizontal
        self.collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: collectionViewLayout)
        self.setupPhotoKeyboardAppearance()
        self.collectionView.register(CameraCell.self, forCellWithReuseIdentifier: CameraCell.reuseIdentifier)
        self.collectionView.register(AssetCell.self, forCellWithReuseIdentifier: AssetCell.reuseIdentifier)
        self.collectionView.register(CameraKeyboardPermissionsCell.self, forCellWithReuseIdentifier: CameraKeyboardPermissionsCell.reuseIdentifier)
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.translatesAutoresizingMaskIntoConstraints = false
        self.collectionView.allowsMultipleSelection = false
        self.collectionView.allowsSelection = true
        self.collectionView.backgroundColor = UIColor.clear
        self.collectionView.bounces = false
    }

    private func setupPhotoKeyboardAppearance() {
        self.view.backgroundColor = SemanticColors.View.backgroundConversationView

        if permissions.areCameraAndPhotoLibraryAuthorized {
            self.collectionView.delaysContentTouches = true
        } else {
            self.collectionView.delaysContentTouches = false
        }

        if permissions.isPhotoLibraryAuthorized,
           mediaSharingRestrictionsMananger.hasAccessToCameraRoll {
            self.collectionViewLayout.minimumLineSpacing = 1
            self.collectionViewLayout.minimumInteritemSpacing = 0.5
            self.collectionViewLayout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 1)
            self.cameraRollButton.isHidden = false
        } else {
            self.collectionViewLayout.minimumLineSpacing = 0
            self.collectionViewLayout.minimumInteritemSpacing = 0
            self.collectionViewLayout.sectionInset = .zero
            self.cameraRollButton.isHidden = true
        }
    }

    func scrollToCamera(animated: Bool) {
        let endOfListX = UIApplication.isLeftToRightLayout ? 0 : self.collectionView.contentSize.width - 10
        self.collectionView.scrollRectToVisible(
            CGRect(x: endOfListX,
                   y: 0,
                   width: 10,
                   height: 10),
            animated: animated
        )
    }

    // MARK: - Actions

    @objc
    func goBackPressed(_ sender: AnyObject) {
        scrollToCamera(animated: true)
    }

    @objc
    func openCameraRollPressed(_ sender: AnyObject) {
        self.delegate?.cameraKeyboardViewControllerWantsToOpenCameraRoll(self)
    }

    // MARK: - Methods

    private func forwardSelectedPhotoAsset(_ asset: PHAsset) {
        let completeBlock = { (data: Data?, uti: String?) in
            guard let data else { return }

            let returnData: Data
            if (uti == "public.heif") ||
                (uti == "public.heic"),
               let convertedJPEGData = data.convertHEIFToJPG() {
                returnData = convertedJPEGData
            } else {
                returnData = data
            }

            DispatchQueue.main.async(execute: {
                self.delegate?.cameraKeyboardViewController(
                    self,
                    didSelectImageData: returnData,
                    isFromCamera: false,
                    uti: uti
                )
            })
        }

        let limit = CGFloat.Image.maxSupportedLength
        if CGFloat(asset.pixelWidth) > limit || CGFloat(asset.pixelHeight) > limit {

            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = false
            options.resizeMode = .exact
            options.isSynchronous = false

            self.imageManagerType.defaultInstance.requestImage(for: asset, targetSize: CGSize(width: limit, height: limit), contentMode: .aspectFit, options: options, resultHandler: { image, info in
                if let image {
                    let data = image.jpegData(compressionQuality: 0.9)
                    completeBlock(data, info?["PHImageFileUTIKey"] as? String)
                } else {
                    options.isSynchronous = true
                    DispatchQueue.main.async {
                        self.activityIndicator.start()
                    }

                    self.imageManagerType.defaultInstance.requestImage(for: asset, targetSize: CGSize(width: limit, height: limit), contentMode: .aspectFit, options: options, resultHandler: { image, info in
                        DispatchQueue.main.async {
                            self.activityIndicator.stop()
                        }

                        if let image {
                            let data = image.jpegData(compressionQuality: 0.9)
                            completeBlock(data, info?["PHImageFileUTIKey"] as? String)
                        } else {
                            zmLog.error("Failure: cannot fetch image")
                        }
                    })
                }

            })
        } else {
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = false
            options.isSynchronous = false

            self.imageManagerType.defaultInstance.requestImageData(for: asset, options: options) { data, uti, _, _ in

                guard let data else {
                    options.isNetworkAccessAllowed = true
                    DispatchQueue.main.async {
                        self.activityIndicator.start()
                    }

                    self.imageManagerType.defaultInstance.requestImageData(for: asset, options: options) { data, uti, _, _ in
                        DispatchQueue.main.async {
                            self.activityIndicator.stop()
                        }
                        guard let data else {
                            zmLog.error("Failure: cannot fetch image")
                            return
                        }

                        completeBlock(data, uti)
                    }

                    return
                }

                completeBlock(data, uti)
            }
        }
    }

    private func forwardSelectedVideoAsset(_ asset: PHAsset) {
        activityIndicator.start()
        guard let fileLengthLimit: UInt64 = ZMUserSession.shared()?.maxUploadFileSize else { return }

        asset.getVideoURL { url in
            DispatchQueue.main.async {
                self.activityIndicator.stop()
            }

            guard let url else { return }

            DispatchQueue.main.async {
                self.activityIndicator.start()
            }

            AVURLAsset.convertVideoToUploadFormat(
                at: url,
                fileLengthLimit: Int64(fileLengthLimit)
            ) { resultURL, asset, error in
                DispatchQueue.main.async {
                    self.activityIndicator.stop()
                }

                guard error == nil,
                      let resultURL,
                      let asset else { return }

                DispatchQueue.main.async(execute: {
                    self.delegate?.cameraKeyboardViewController(
                        self,
                        didSelectVideo: resultURL,
                        duration: CMTimeGetSeconds(asset.duration)
                    )
                })
            }
        }

    }

}

// MARK: - CameraKeyboardViewController - UICollectionViewDelegate - UICollectionViewDataSource

extension CameraKeyboardViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDelegate, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        defer {
            setupPhotoKeyboardAppearance()
        }
        guard permissions.areCameraOrPhotoLibraryAuthorized,
              mediaSharingRestrictionsMananger.hasAccessToCameraRoll else {
            return 1
        }
        return 2
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard permissions.areCameraOrPhotoLibraryAuthorized else { return 1 }

        switch CameraKeyboardSection(rawValue: UInt(section))! {
        case .camera:
            return 1
        case .photos:
            guard let assetLibrary else {
                return 1
            }
            return permissions.isPhotoLibraryAuthorized ? Int(assetLibrary.count) : 1
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        guard permissions.areCameraOrPhotoLibraryAuthorized else {
            return deniedAuthorizationCell(for: .cameraAndPhotos, collectionView: collectionView, indexPath: indexPath)
        }

        switch CameraKeyboardSection(rawValue: UInt((indexPath as NSIndexPath).section))! {
        case .camera:

            guard permissions.isCameraAuthorized else {
                return deniedAuthorizationCell(for: .camera, collectionView: collectionView, indexPath: indexPath)
            }

            if shouldBlockCallingRelatedActions {
                return deniedAuthorizationCell(for: .ongoingCall, collectionView: collectionView, indexPath: indexPath)
            }

            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CameraCell.reuseIdentifier, for: indexPath) as! CameraCell
            cell.delegate = self
            return cell

        case .photos:

            guard permissions.isPhotoLibraryAuthorized else {
                return deniedAuthorizationCell(for: .photos, collectionView: collectionView, indexPath: indexPath)
            }

            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AssetCell.reuseIdentifier, for: indexPath) as! AssetCell

            cell.manager = self.imageManagerType.defaultInstance

            if let asset = try? assetLibrary?.asset(atIndex: UInt((indexPath as NSIndexPath).row)) {
                cell.asset = asset
            }

            return cell
        }
    }

    // swiftlint:disable:next todo_requires_jira_link
    // TODO: a protocol for this for testing
    @objc
    var shouldBlockCallingRelatedActions: Bool {
        return ZMUserSession.shared()?.isCallOngoing ?? false
    }

    private func deniedAuthorizationCell(for type: DeniedAuthorizationType, collectionView: UICollectionView, indexPath: IndexPath) -> CameraKeyboardPermissionsCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CameraKeyboardPermissionsCell.reuseIdentifier,
                                                      for: indexPath) as! CameraKeyboardPermissionsCell
        cell.configure(deniedAuthorization: type)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard permissions.areCameraOrPhotoLibraryAuthorized else { return collectionView.frame.size }

        switch CameraKeyboardSection(rawValue: UInt((indexPath as NSIndexPath).section))! {
        case .camera:
            return cameraCellSize
        case .photos:
            guard permissions.isPhotoLibraryAuthorized else {
                return CGSize(width: self.view.bounds.size.width - cameraCellSize.width, height: self.view.bounds.size.height)
            }

            let photoSize = self.view.bounds.size.height / 2 - 0.5
            return CGSize(width: photoSize, height: photoSize)
        }
    }

    private var cameraCellSize: CGSize {
        // TODO: [WPB-11615] Before navigation overhaul the width of the camera preview was the same as the left column.
        CGSize(width: view.bounds.size.width / 2, height: view.bounds.size.height)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        guard permissions.areCameraOrPhotoLibraryAuthorized else { return }

        switch CameraKeyboardSection(rawValue: UInt((indexPath as NSIndexPath).section))! {
        case .camera:
            break
        case .photos:
            guard
                permissions.isPhotoLibraryAuthorized,
                let asset = try? assetLibrary?.asset(atIndex: UInt((indexPath as NSIndexPath).row))
            else {
                return
            }

            switch asset.mediaType {
            case .video:
                self.forwardSelectedVideoAsset(asset)

            case .image:
                self.forwardSelectedPhotoAsset(asset)

            default:
                // not supported
                break
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if cell is CameraCell || cell is CameraKeyboardPermissionsCell {
            self.goBackButtonRevealed = true
        }
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if cell is CameraCell || cell is CameraKeyboardPermissionsCell {
            self.goBackButtonRevealed = false

            (cell as? CameraCell)?.updateVideoOrientation()
        }
    }
}

// MARK: - CameraKeyboardViewController - CameraCellDelegate

extension CameraKeyboardViewController: CameraCellDelegate {
    func cameraCellWantsToOpenFullCamera(_ cameraCell: CameraCell) {
        self.delegate?.cameraKeyboardViewControllerWantsToOpenFullScreenCamera(self)
    }

    func cameraCell(_ cameraCell: CameraCell, didPickImageData imageData: Data) {
        self.delegate?.cameraKeyboardViewController(self, didSelectImageData: imageData, isFromCamera: true, uti: nil)
    }
}

// MARK: - CameraKeyboardViewController - AssetLibraryDelegate

extension CameraKeyboardViewController: AssetLibraryDelegate {
    func assetLibraryDidChange(_ library: AssetLibrary) {
        self.collectionView.reloadData()
    }
}

// MARK: - CameraKeyboardViewController - WireCallCenterCallStateObserver

extension CameraKeyboardViewController: WireCallCenterCallStateObserver {
    func callCenterDidChange(callState: CallState, conversation: ZMConversation, caller: UserType, timestamp: Date?, previousCallState: CallState?) {
        // swiftlint:disable:next todo_requires_jira_link
        // TODO: fix undesired camera keyboard openings here
        self.collectionView.reloadItems(at: [IndexPath(item: 0, section: 0)])
    }
}

// MARK: - PHAsset

extension PHAsset {

    func getVideoURL(completionHandler: @escaping ((_ responseURL: URL?) -> Void)) {
        guard mediaType == .video else {
            completionHandler(nil)
            return
        }

        let options: PHVideoRequestOptions = PHVideoRequestOptions()
        options.version = .current
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true

        PHImageManager.default().requestAVAsset(forVideo: self, options: options, resultHandler: { (asset: AVAsset?, _: AVAudioMix?, _: [AnyHashable: Any]?) in
            if let urlAsset = asset as? AVURLAsset {
                let localVideoUrl: URL = urlAsset.url as URL
                completionHandler(localVideoUrl)
            } else {
                completionHandler(nil)
            }
        })
    }
}
