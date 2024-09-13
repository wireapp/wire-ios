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

import avs
import Foundation

protocol CameraCellDelegate: AnyObject {
    func cameraCellWantsToOpenFullCamera(_ cameraCell: CameraCell)
    func cameraCell(_ cameraCell: CameraCell, didPickImageData: Data)
}

final class CameraCell: UICollectionViewCell {
    let cameraController: CameraController?

    let expandButton = IconButton()
    let takePictureButton = IconButton()
    let changeCameraButton = IconButton()

    weak var delegate: CameraCellDelegate?

    override init(frame: CGRect) {
        let camera: SettingsCamera = Settings.shared[.preferredCamera] ?? .front
        self.cameraController = CameraController(camera: camera)

        super.init(frame: frame)

        if let cameraController {
            cameraController.previewLayer.frame = contentView.bounds
            cameraController.previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
            contentView.layer.addSublayer(cameraController.previewLayer)
        }

        contentView.clipsToBounds = true
        contentView.backgroundColor = UIColor.black

        delay(0.01) {
            self.cameraController?.startRunning()
            self.updateVideoOrientation()
        }

        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(deviceOrientationDidChange(_:)),
            name: UIDevice.orientationDidChangeNotification,
            object: .none
        )

        expandButton.setIcon(.fullScreen, size: .tiny, for: [])
        expandButton.setIconColor(UIColor.white, for: [])
        expandButton.translatesAutoresizingMaskIntoConstraints = false
        expandButton.addTarget(self, action: #selector(expandButtonPressed(_:)), for: .touchUpInside)
        expandButton.accessibilityIdentifier = "fullscreenCameraButton"
        contentView.addSubview(expandButton)

        takePictureButton.setIcon(.cameraShutter, size: 36, for: [])
        takePictureButton.setIconColor(UIColor.white, for: [])
        takePictureButton.translatesAutoresizingMaskIntoConstraints = false
        takePictureButton.addTarget(self, action: #selector(shutterButtonPressed(_:)), for: .touchUpInside)
        takePictureButton.accessibilityIdentifier = "takePictureButton"
        contentView.addSubview(takePictureButton)

        changeCameraButton.setIcon(.flipCamera, size: .tiny, for: [])
        changeCameraButton.setIconColor(UIColor.white, for: [])
        changeCameraButton.translatesAutoresizingMaskIntoConstraints = false
        changeCameraButton.addTarget(self, action: #selector(changeCameraPressed(_:)), for: .touchUpInside)
        changeCameraButton.accessibilityIdentifier = "changeCameraButton"
        contentView.addSubview(changeCameraButton)

        for button in [takePictureButton, expandButton, changeCameraButton] {
            button.layer.shadowColor = UIColor.black.cgColor
            button.layer.shadowOffset = CGSize(width: 0, height: 0)
            button.layer.shadowRadius = 0.5
            button.layer.shadowOpacity = 0.5
        }

        createConstraints()
    }

    private func createConstraints() {
        [
            expandButton,
            takePictureButton,
            changeCameraButton,
        ].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        NSLayoutConstraint.activate([
            expandButton.widthAnchor.constraint(equalToConstant: 40),
            expandButton.widthAnchor.constraint(equalTo: expandButton.heightAnchor),

            expandButton.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -12),
            expandButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),

            takePictureButton.widthAnchor.constraint(equalToConstant: 60),
            takePictureButton.widthAnchor.constraint(equalTo: takePictureButton.heightAnchor),

            takePictureButton.bottomAnchor.constraint(
                equalTo: contentView.bottomAnchor,
                constant: -(6 + UIScreen.safeArea.bottom)
            ),
            takePictureButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            changeCameraButton.widthAnchor.constraint(equalToConstant: 40),
            changeCameraButton.widthAnchor.constraint(equalTo: changeCameraButton.heightAnchor),

            changeCameraButton.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 12),
            changeCameraButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
        ])
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window == .none { cameraController?.stopRunning() } else { cameraController?.startRunning() }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        cameraController?.previewLayer.frame = contentView.bounds
        updateVideoOrientation()
    }

    func updateVideoOrientation() {
        guard UIDevice.current.userInterfaceIdiom == .pad else { return }
        cameraController?.updatePreviewOrientation()
    }

    @objc
    func deviceOrientationDidChange(_: Notification!) {
        updateVideoOrientation()
    }

    // MARK: - Actions

    @objc
    func expandButtonPressed(_: AnyObject) {
        delegate?.cameraCellWantsToOpenFullCamera(self)
    }

    @objc
    func shutterButtonPressed(_: AnyObject) {
        cameraController?.capturePhoto { data, error in
            if error == nil {
                self.delegate?.cameraCell(self, didPickImageData: data!)
            }
        }
    }

    @objc
    func changeCameraPressed(_: AnyObject) {
        cameraController?.switchCamera { currentCamera in
            Settings.shared[.preferredCamera] = currentCamera
        }
    }
}
