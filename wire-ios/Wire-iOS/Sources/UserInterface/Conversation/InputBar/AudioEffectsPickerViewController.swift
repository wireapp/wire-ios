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
import UIKit
import WireCommonComponents
import WireDataModel
import WireDesign

protocol AudioEffectsPickerDelegate: AnyObject {
    func audioEffectsPickerDidPickEffect(_ picker: AudioEffectsPickerViewController, effect: AVSAudioEffectType, resultFilePath: String)
}

final class AudioEffectsPickerViewController: UIViewController {

    let recordingPath: String
    private let duration: TimeInterval
    private let fileMetadataGenerator = FileMetaDataGenerator()
    weak var delegate: AudioEffectsPickerDelegate?

    private var audioPlayerController: AudioPlayerController? {
        didSet {
            if audioPlayerController == .none {
                let selector = #selector(AudioEffectsPickerViewController.updatePlayProgressTime)
                NSObject.cancelPreviousPerformRequests(withTarget: self, selector: selector, object: .none)
            }
        }
    }

    enum State {
        case none
        case tip
        case time
        case playing
    }

    var state: State = .none

    private let effects: [AVSAudioEffectType] = AVSAudioEffectType.displayedEffects
    var normalizedLoudness: [Float] = []
    private var lastLayoutSize = CGSize.zero

    var selectedAudioEffect: AVSAudioEffectType = .none {
        didSet {
            if selectedAudioEffect == .reverse {
                progressView.samples = normalizedLoudness.reversed()
            } else {
                progressView.samples = normalizedLoudness
            }

            setState(.playing, animated: true)

            if let audioPlayerController, oldValue == selectedAudioEffect {

                if audioPlayerController.state == .playing {
                    audioPlayerController.stop()
                } else {
                    audioPlayerController.play()
                }

                return
            }

            if selectedAudioEffect != .none {
                audioPlayerController?.stop()

                let effectPath = (NSTemporaryDirectory() as NSString).appendingPathComponent("effect.wav")
                effectPath.deleteFileAtPath()
                self.selectedAudioEffect.apply(self.recordingPath, outPath: effectPath) {
                    self.delegate?.audioEffectsPickerDidPickEffect(self, effect: self.selectedAudioEffect, resultFilePath: effectPath)

                    self.playMedia(effectPath)
                }
            } else {
                delegate?.audioEffectsPickerDidPickEffect(self, effect: .none, resultFilePath: recordingPath)
                playMedia(recordingPath)
            }
        }
    }

    private static let effectRows = 2
    private static let effectColumns = 4

    deinit {
        tearDown()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatal("init?(coder) is not implemented")
    }

    init(recordingPath: String, duration: TimeInterval) {
        self.duration = duration
        self.recordingPath = recordingPath
        super.init(nibName: .none, bundle: .none)
    }

    func tearDown() {
        audioPlayerController?.stop()
        audioPlayerController?.tearDown()
        audioPlayerController = .none
    }

    private let collectionViewLayout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
    private var collectionView: UICollectionView!
    private let statusBoxView = UIView()
    let progressView = WaveformProgressView()
    private let subtitleLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()

        createCollectionView()
        progressView.translatesAutoresizingMaskIntoConstraints = false

        subtitleLabel.textAlignment = .center
        subtitleLabel.font = FontSpec(.small, .light).font!
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        statusBoxView.translatesAutoresizingMaskIntoConstraints = false

        statusBoxView.addSubview(progressView)
        statusBoxView.addSubview(subtitleLabel)
        view.addSubview(statusBoxView)
        view.addSubview(collectionView)

        [collectionView, progressView, subtitleLabel, statusBoxView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        NSLayoutConstraint.activate([
          collectionView.leftAnchor.constraint(equalTo: view.leftAnchor),
          collectionView.topAnchor.constraint(equalTo: view.topAnchor),
          collectionView.rightAnchor.constraint(equalTo: view.rightAnchor),

          statusBoxView.topAnchor.constraint(equalTo: collectionView.bottomAnchor, constant: 8),
          statusBoxView.heightAnchor.constraint(equalToConstant: 24),
          statusBoxView.leftAnchor.constraint(equalTo: collectionView.leftAnchor, constant: 48),
          statusBoxView.rightAnchor.constraint(equalTo: collectionView.rightAnchor, constant: -48),
          statusBoxView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

          progressView.topAnchor.constraint(equalTo: statusBoxView.topAnchor),
          progressView.bottomAnchor.constraint(equalTo: statusBoxView.bottomAnchor),
          progressView.leftAnchor.constraint(equalTo: statusBoxView.leftAnchor),
          progressView.rightAnchor.constraint(equalTo: statusBoxView.rightAnchor),
          subtitleLabel.topAnchor.constraint(equalTo: statusBoxView.topAnchor),
          subtitleLabel.bottomAnchor.constraint(equalTo: statusBoxView.bottomAnchor),
          subtitleLabel.leftAnchor.constraint(equalTo: statusBoxView.leftAnchor),
          subtitleLabel.rightAnchor.constraint(equalTo: statusBoxView.rightAnchor)
        ])

        // Do not load in tests, which may cause exception break point to break when loading audio assets
        if !ProcessInfo.processInfo.isRunningTests {
             loadLevels()
        }

        setState(.time, animated: false)
    }

    private func createCollectionView() {
        collectionViewLayout.scrollDirection = .vertical
        collectionViewLayout.minimumLineSpacing = 0
        collectionViewLayout.minimumInteritemSpacing = 0
        collectionViewLayout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: collectionViewLayout)
        collectionView.register(AudioEffectCell.self, forCellWithReuseIdentifier: AudioEffectCell.reuseIdentifier)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.allowsMultipleSelection = false
        collectionView.allowsSelection = true
        collectionView.backgroundColor = UIColor.clear
    }

    private func loadLevels() {
        let url = URL(fileURLWithPath: recordingPath)
        fileMetadataGenerator.metadataForFile(
            at: url,
            name: url.lastPathComponent
        ) { metadata in
            DispatchQueue.main.async {
                if let audioMetadata = metadata as? ZMAudioMetadata {
                    self.normalizedLoudness = audioMetadata.normalizedLoudness
                    self.progressView.samples = audioMetadata.normalizedLoudness
                }
            }
        }
    }

    override func removeFromParent() {
        tearDown()
        super.removeFromParent()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        selectCurrentFilter()
        delay(2) {
            if self.state == .time {
                self.setState(.tip, animated: true)
            }
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        tearDown()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !lastLayoutSize.equalTo(view.bounds.size) {
            lastLayoutSize = view.bounds.size
            collectionViewLayout.invalidateLayout()
            collectionView.reloadData()
            selectCurrentFilter()
        }
    }

    func setState(_ state: State, animated: Bool) {
        if state == state {
            return
        }

        self.state = state

        switch state {
        case .tip:
            subtitleLabel.text = L10n.Localizable.Conversation.InputBar.AudioMessage.Keyboard.filterTip.localizedUppercase
            subtitleLabel.textColor = SemanticColors.Label.textDefault
        case .time:
            let duration: Int
            if let player = audioPlayerController?.player {
                duration = Int(ceil(player.duration))
            } else {
                duration = Int(ceil(self.duration))
            }

            let (seconds, minutes) = (duration % 60, duration / 60)
            subtitleLabel.text = String(format: "%d:%02d", minutes, seconds)
            subtitleLabel.accessibilityValue = subtitleLabel.text
            subtitleLabel.textColor = SemanticColors.Label.textDefault
        default:
            // no-op
            break
        }

        let change = {
            self.subtitleLabel.isHidden = self.state == .playing
            self.progressView.isHidden = self.state != .playing
        }

        if animated {
            let options: UIView.AnimationOptions = (state == .playing) ? .transitionFlipFromTop : .transitionFlipFromBottom
            UIView.transition(with: statusBoxView, duration: 0.35, options: options, animations: change, completion: .none)
        } else {
            change()
        }
    }

    private func selectCurrentFilter() {
        if let index = effects.firstIndex(where: {
            $0 == selectedAudioEffect
        }) {
            let indexPath = IndexPath(item: index, section: 0)
            collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
        }
    }

    private func playMedia(_ atPath: String) {
        audioPlayerController?.tearDown()

        audioPlayerController = try? AudioPlayerController(contentOf: URL(fileURLWithPath: atPath))
        audioPlayerController?.delegate = self
        audioPlayerController?.play()
        updatePlayProgressTime()
    }

    @objc private func updatePlayProgressTime() {
        let selector = #selector(AudioEffectsPickerViewController.updatePlayProgressTime)
        if let player = audioPlayerController?.player {
            progressView.progress = Float(player.currentTime / player.duration)

            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: selector, object: .none)
            perform(selector, with: .none, afterDelay: 0.05)
        } else {
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: selector, object: .none)
        }
    }
}

extension AudioEffectsPickerViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return effects.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AudioEffectCell.reuseIdentifier, for: indexPath) as! AudioEffectCell
        cell.effect = effects[indexPath.item]
        let lastColumn = ((indexPath as NSIndexPath).item % type(of: self).effectColumns) == type(of: self).effectColumns - 1
        let lastRow = Int(floorf(Float((indexPath as NSIndexPath).item) / Float(type(of: self).effectColumns))) == type(of: self).effectRows - 1

        cell.borders = (lastColumn ? AudioEffectCellBorders.None : AudioEffectCellBorders.Right).union(lastRow ? [] : [AudioEffectCellBorders.Bottom])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: CGFloat(Int(collectionView.bounds.width) / type(of: self).effectColumns),
                          height: CGFloat(Int(collectionView.bounds.height) / type(of: self).effectRows))
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedAudioEffect = effects[indexPath.item]
    }
}

extension AudioEffectsPickerViewController: AudioPlayerControllerDelegate {

    func audioPlayerControllerDidFinishPlaying() {
        setState(.time, animated: true)
    }

}

private protocol AudioPlayerControllerDelegate: AnyObject {

    func audioPlayerControllerDidFinishPlaying()

}

private final class AudioPlayerController: NSObject, MediaPlayer, AVAudioPlayerDelegate {

    let player: AVAudioPlayer
    weak var delegate: AudioPlayerControllerDelegate?
    weak var mediaManager: MediaPlayerDelegate? = AppDelegate.shared.mediaPlaybackManager

    init(contentOf URL: URL) throws {
        player = try AVAudioPlayer(contentsOf: URL)

        super.init()

        player.delegate = self
    }

    deinit {
        tearDown()
    }

    func tearDown() {
        mediaManager?.mediaPlayer(self, didChangeTo: .completed)
        player.delegate = nil
    }

    var state: MediaPlayerState? {
        return player.isPlaying ? .playing : .completed
    }

    var title: String? {
        return nil
    }

    var sourceMessage: ZMConversationMessage? {
        return nil
    }

    func play() {
        mediaManager?.mediaPlayer(self, didChangeTo: .playing)
        player.currentTime = 0
        player.delegate = self
        player.play()
    }

    func pause() {
        player.pause()
    }

    func stop() {
        player.pause()
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if player == player {
            tearDown()
            delegate?.audioPlayerControllerDidFinishPlaying()
        }
    }

}
