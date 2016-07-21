// 
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
import CocoaLumberjackSwift
import Cartography


@objc public protocol AudioEffectsPickerDelegate: NSObjectProtocol {
    func audioEffectsPickerDidPickEffect(picker: AudioEffectsPickerViewController, effect: AVSAudioEffectType, resultFilePath: String)
}

@objc public final class AudioEffectsPickerViewController: UIViewController {
    
    public let recordingPath: String
    private let duration: NSTimeInterval
    public weak var delegate: AudioEffectsPickerDelegate?
    
    private var audioPlayer: AVAudioPlayer? {
        didSet {
            if self.audioPlayer == .None {
                let selector = #selector(AudioEffectsPickerViewController.updatePlayProgressTime)
                NSObject.cancelPreviousPerformRequestsWithTarget(self, selector: selector, object: .None)
            }
        }
    }
    
    internal enum State {
        case None
        case Tip
        case Time
        case Playing
    }
    
    internal var state: State = .None
    
    private let effects: [AVSAudioEffectType] = AVSAudioEffectType.displayedEffects
    internal var normalizedLoudness: [Float] = []
    private var lastLayoutSize = CGSizeZero
    
    internal var selectedAudioEffect: AVSAudioEffectType = .None {
        didSet {
            if self.selectedAudioEffect == .Reverse {
                self.progressView.samples = self.normalizedLoudness.reverse()
            }
            else {
                self.progressView.samples = self.normalizedLoudness
            }
            
            self.setState(.Playing, animated: true)

            if self.audioPlayer != .None && oldValue == self.selectedAudioEffect {
                let player = self.audioPlayer!
                if player.playing {
                    player.stop()
                }
                else {
                    player.currentTime = 0
                    player.play()
                }
            
                return
            }
            
            if self.selectedAudioEffect != .None {
                self.audioPlayer?.stop()
                
                
                let effectPath = (NSTemporaryDirectory() as NSString).stringByAppendingPathComponent("effect.wav")
                effectPath.deleteFileAtPath()
                self.selectedAudioEffect.apply(self.recordingPath, outPath: effectPath) {
                    self.delegate?.audioEffectsPickerDidPickEffect(self, effect: self.selectedAudioEffect, resultFilePath: effectPath)
                    
                    self.playMedia(effectPath)
                }
            }
            else {
                self.playMedia(self.recordingPath)
            }
        }
    }
    
    private static let effectRows = 2
    private static let effectColumns = 4
    
    deinit {
        self.audioPlayer?.stop()
        self.audioPlayer = .None
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatal("init?(coder) is not implemented")
    }
    
    public init(recordingPath: String, duration: NSTimeInterval) {
        self.duration = duration
        self.recordingPath = recordingPath
        super.init(nibName: .None, bundle: .None)
    }
    
    private let collectionViewLayout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
    private var collectionView: UICollectionView!
    private let statusBoxView = UIView()
    internal let progressView = WaveformProgressView()
    private let subtitleLabel = UILabel()
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        self.createCollectionView()
        self.progressView.barColor = UIColor.whiteColor()
        self.progressView.translatesAutoresizingMaskIntoConstraints = false
        
        self.subtitleLabel.textAlignment = .Center
        self.subtitleLabel.font = UIFont(magicIdentifier: "style.text.small.font_spec_light")
        self.subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        self.statusBoxView.translatesAutoresizingMaskIntoConstraints = false

        self.statusBoxView.addSubview(self.progressView)
        self.statusBoxView.addSubview(self.subtitleLabel)
        self.view.addSubview(self.statusBoxView)
        self.view.addSubview(self.collectionView)
        
        constrain(self.view, self.collectionView, self.progressView, self.subtitleLabel, self.statusBoxView) { view, collectionView, progressView, subtitleLabel, statusBoxView in
            collectionView.left == view.left
            collectionView.top == view.top
            collectionView.right == view.right

            statusBoxView.top == collectionView.bottom + 8
            statusBoxView.height == 24
            statusBoxView.left == collectionView.left + 48
            statusBoxView.right == collectionView.right - 48
            statusBoxView.bottom == view.bottom
            
            progressView.edges == statusBoxView.edges
            subtitleLabel.edges == statusBoxView.edges
        }
        
        self.loadLevels()
        
        self.setState(.Time, animated: false)
    }
    
    private func createCollectionView() {
        self.collectionViewLayout.scrollDirection = .Vertical
        self.collectionViewLayout.minimumLineSpacing = 0
        self.collectionViewLayout.minimumInteritemSpacing = 0
        self.collectionViewLayout.sectionInset = UIEdgeInsetsMake(0, 0, 0, 0)
        self.collectionView = UICollectionView(frame: CGRectZero, collectionViewLayout: collectionViewLayout)
        self.collectionView.registerClass(AudioEffectCell.self, forCellWithReuseIdentifier: AudioEffectCell.reuseIdentifier)
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.translatesAutoresizingMaskIntoConstraints = false
        self.collectionView.allowsMultipleSelection = false
        self.collectionView.allowsSelection = true
        self.collectionView.backgroundColor = UIColor.clearColor()
    }
    
    private func loadLevels() {
        let url = NSURL(fileURLWithPath: recordingPath)
        FileMetaDataGenerator.metadataForFileAtURL(url, UTI: url.UTI()) { metadata in
            dispatch_async(dispatch_get_main_queue(), {
                if let audioMetadata = metadata as? ZMAudioMetadata {
                    self.normalizedLoudness = audioMetadata.normalizedLoudness
                    self.progressView.samples = audioMetadata.normalizedLoudness
                }
            })
        }
    }
    
    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.selectCurrentFilter()
        delay(2) {
            if self.state == .Time {
                self.setState(.Tip, animated: true)
            }
        }
    }
    
    public override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        self.audioPlayer?.stop()
        self.audioPlayer = .None
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !CGSizeEqualToSize(self.lastLayoutSize, self.view.bounds.size) {
            self.lastLayoutSize = self.view.bounds.size
            self.collectionViewLayout.invalidateLayout()
            self.collectionView.reloadData()
            self.selectCurrentFilter()
        }
    }
    
    internal func setState(state: State, animated: Bool) {
        if self.state == state {
            return
        }
        
        self.state = state
        
        let colorScheme = ColorScheme()
        colorScheme.variant = .Dark
        
        
        switch self.state {
        case .Tip:
            self.subtitleLabel.text = "conversation.input_bar.audio_message.keyboard.filter_tip".localized.uppercaseString
            self.subtitleLabel.textColor = colorScheme.colorWithName(ColorSchemeColorTextForeground)
        case .Time:
            let duration: Int
            if let player = self.audioPlayer {
                duration = Int(ceil(player.duration))
            }
            else {
                duration = Int(ceil(self.duration))
            }
            
            let (seconds, minutes) = (duration % 60, duration / 60)
            self.subtitleLabel.text = String(format: "%d:%02d", minutes, seconds)
            self.subtitleLabel.accessibilityValue = self.subtitleLabel.text
            self.subtitleLabel.textColor = colorScheme.colorWithName(ColorSchemeColorTextForeground)
        default:
            // no-op
            break
        }
        
        let change = {
            self.subtitleLabel.hidden = self.state == .Playing
            self.progressView.hidden = self.state != .Playing
        }
        
        if animated {
            let options: UIViewAnimationOptions = (state == .Playing) ? .TransitionFlipFromTop : .TransitionFlipFromBottom
            UIView.transitionWithView(self.statusBoxView, duration: 0.35, options: options, animations: change, completion: .None)
        }
        else {
            change()
        }
    }
    
    private func selectCurrentFilter() {
        if let index = self.effects.indexOf({
            $0 == self.selectedAudioEffect
        }) {
            self.collectionView.selectItemAtIndexPath(NSIndexPath(forItem:index, inSection:0), animated: false, scrollPosition: .None)
        }
    }
    
    private func playMedia(atPath: String) {
        Analytics.shared()?.tagPreviewedAudioMessageRecording(.Keyboard)
        self.audioPlayer = try? AVAudioPlayer(contentsOfURL: NSURL(fileURLWithPath: atPath))
        self.audioPlayer?.delegate = self
        self.audioPlayer?.play()
        self.updatePlayProgressTime()
    }
    
    @objc private func updatePlayProgressTime() {
        let selector = #selector(AudioEffectsPickerViewController.updatePlayProgressTime)
        if let player = self.audioPlayer {
            self.progressView.progress = Float(player.currentTime / player.duration)
            
            NSObject.cancelPreviousPerformRequestsWithTarget(self, selector: selector, object: .None)
            self.performSelector(selector, withObject: .None, afterDelay: 0.05)
        }
        else {
            NSObject.cancelPreviousPerformRequestsWithTarget(self, selector: selector, object: .None)
        }
    }
}

extension AudioEffectsPickerViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    public func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.effects.count
    }
    
    public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(AudioEffectCell.reuseIdentifier, forIndexPath: indexPath) as! AudioEffectCell
        cell.effect = self.effects[indexPath.item]
        let lastColumn = (indexPath.item % self.dynamicType.effectColumns) == self.dynamicType.effectColumns - 1
        let lastRow = Int(floorf(Float(indexPath.item) / Float(self.dynamicType.effectColumns))) == self.dynamicType.effectRows - 1

        cell.borders = (lastColumn ? AudioEffectCellBorders.None : AudioEffectCellBorders.Right).union(lastRow ? [] : [AudioEffectCellBorders.Bottom])
        return cell
    }
    
    public func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSizeMake(CGFloat(Int(collectionView.bounds.width) / self.dynamicType.effectColumns),
                          CGFloat(Int(collectionView.bounds.height) / self.dynamicType.effectRows))
    }
    
    public func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        guard ((try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord, withOptions: .DefaultToSpeaker)) != nil) else {
            DDLogError("Cannot set audio session to CategoryPlayAndRecord, speaker")
            return
        }
        
        self.selectedAudioEffect = self.effects[indexPath.item]
    }
}

extension AudioEffectsPickerViewController: AVAudioPlayerDelegate {
    public func audioPlayerDidFinishPlaying(player: AVAudioPlayer, successfully flag: Bool) {
        if player == self.audioPlayer {
            self.setState(.Time, animated: true)
        }
    }
}
