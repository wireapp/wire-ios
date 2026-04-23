//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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
import UIKit

/// A minimal video recorder for Mac (Designed for iPad).
/// UIImagePickerController with .camera source crashes on Mac because Portrait Effects
/// tries to create Metal textures with unsupported IOSurface formats. This replaces it.
final class MacVideoRecorderViewController: UIViewController {

    var maxDuration: TimeInterval = 240
    var onVideoRecorded: ((URL) -> Void)?

    private let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.wire.mac-video-recorder.session")
    private let movieOutput = AVCaptureMovieFileOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var recordingTimer: Timer?
    private var elapsedSeconds = 0

    private lazy var recordButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.cornerStyle = .capsule
        config.baseForegroundColor = .white
        config.baseBackgroundColor = .systemRed
        config.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 28, bottom: 14, trailing: 28)
        let button = UIButton(configuration: config)
        button.setTitle(L10n.Localizable.Content.File.takeVideo, for: .normal)
        button.setTitle("Stop", for: .selected)
        button.addTarget(self, action: #selector(toggleRecording), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var cancelButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.baseForegroundColor = .white
        let button = UIButton(configuration: config)
        button.setTitle(L10n.Localizable.General.cancel, for: .normal)
        button.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var timerLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .monospacedDigitSystemFont(ofSize: 17, weight: .semibold)
        label.text = formatTime(0)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()

    private lazy var recordingIndicator: UIView = {
        let view = UIView()
        view.backgroundColor = .systemRed
        view.layer.cornerRadius = 5
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        NSLayoutConstraint.activate([
            view.widthAnchor.constraint(equalToConstant: 10),
            view.heightAnchor.constraint(equalToConstant: 10)
        ])
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupSession()
        setupUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        sessionQueue.async { self.session.startRunning() }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if movieOutput.isRecording { movieOutput.stopRecording() }
        sessionQueue.async { self.session.stopRunning() }
        recordingTimer?.invalidate()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer.frame = view.bounds
    }

    private func setupSession() {
        session.beginConfiguration()
        // .medium avoids high-quality video configurations that tend to trigger Portrait Effects
        session.sessionPreset = .medium
        session.automaticallyConfiguresCaptureDeviceForWideColor = false

        if let device = AVCaptureDevice.default(for: .video),
           let input = try? AVCaptureDeviceInput(device: device),
           session.canAddInput(input) {
            session.addInput(input)
        }

        if let device = AVCaptureDevice.default(for: .audio),
           let input = try? AVCaptureDeviceInput(device: device),
           session.canAddInput(input) {
            session.addInput(input)
        }
        
        if session.canAddOutput(movieOutput) {
            session.addOutput(movieOutput)
        }

        session.commitConfiguration()

        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.insertSublayer(previewLayer, at: 0)
    }

    private func setupUI() {
        let timerStack = UIStackView(arrangedSubviews: [recordingIndicator, timerLabel])
        timerStack.axis = .horizontal
        timerStack.spacing = 6
        timerStack.alignment = .center
        timerStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(timerStack)

        view.addSubview(cancelButton)
        view.addSubview(recordButton)

        NSLayoutConstraint.activate([
            timerStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            timerStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),

            recordButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            recordButton.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                constant: -28
            ),

            cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            cancelButton.centerYAnchor.constraint(equalTo: recordButton.centerYAnchor)
        ])
    }

    @objc private func toggleRecording() {
        if movieOutput.isRecording {
            movieOutput.stopRecording()
            recordButton.isSelected = false
            recordingTimer?.invalidate()
        } else {
            let url = URL(fileURLWithPath: NSTemporaryDirectory())
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("mov")
            movieOutput.maxRecordedDuration = CMTime(seconds: maxDuration, preferredTimescale: 600)
            movieOutput.startRecording(to: url, recordingDelegate: self)
            recordButton.isSelected = true
            elapsedSeconds = 0
            timerLabel.isHidden = false
            recordingIndicator.isHidden = false
            timerLabel.text = formatTime(0)
            recordingTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                guard let self else { return }
                self.elapsedSeconds += 1
                self.timerLabel.text = self.formatTime(self.elapsedSeconds)
            }
        }
    }

    @objc private func cancelTapped() {
        if movieOutput.isRecording { movieOutput.stopRecording() }
        dismiss(animated: true)
    }

    private func formatTime(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}

extension MacVideoRecorderViewController: AVCaptureFileOutputRecordingDelegate {

    func fileOutput(
        _ output: AVCaptureFileOutput,
        didFinishRecordingTo outputFileURL: URL,
        from connections: [AVCaptureConnection],
        error: Error?
    ) {
        DispatchQueue.main.async {
            self.recordButton.isSelected = false
            self.recordingTimer?.invalidate()
            self.recordingIndicator.isHidden = true

            guard error == nil else { return }

            self.dismiss(animated: true) {
                self.onVideoRecorded?(outputFileURL)
            }
        }
    }
}
