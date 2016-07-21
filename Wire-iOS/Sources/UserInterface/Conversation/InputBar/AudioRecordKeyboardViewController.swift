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
import Cartography
import CocoaLumberjackSwift


@objc final public class AudioRecordKeyboardViewController: UIViewController, AudioRecordBaseViewController {
    enum State {
        case Ready, Recording, Effects
    }
    
    private let topContainer = UIView()
    private let topSeparator = UIView()
    private let bottomToolbar = UIView()
    
    private let tipLabel = UILabel()
    private var recordTapGestureRecognizer: UITapGestureRecognizer!
    internal let recordButton = IconButton()
    internal let stopRecordButton = IconButton()

    private let audioPreviewView = WaveFormView()
    private let timeLabel = UILabel()
    
    internal let confirmButton = IconButton()
    internal let redoButton = IconButton()
    internal let cancelButton = IconButton()

    private var accentColorChangeHandler: AccentColorChangeHandler?
    private var effectPickerViewController: AudioEffectsPickerViewController?
    
    private var currentEffect: AVSAudioEffectType = .None
    private var currentEffectFilePath: String?
    
    private(set) var state: State = .Ready {
        didSet {
            if oldValue != state {
                updateRecordingState(self.state)
            }
        }
    }
    public let recorder: AudioRecorderType
    public weak var delegate: AudioRecordViewControllerDelegate?
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc convenience init() {
        self.init(audioRecorder: AudioRecorder(format: .WAV, maxRecordingDuration: 25.0 * 60.0)!)
    }
    
    init(audioRecorder: AudioRecorderType) {
        self.recorder = audioRecorder
        super.init(nibName: nil, bundle: nil)
        configureViews()
        configureAudioRecorder()
        createConstraints()
        
        if DeveloperMenuState.developerMenuEnabled() && Settings.sharedSettings().maxRecordingDurationDebug != 0 {
            self.recorder.maxRecordingDuration = Settings.sharedSettings().maxRecordingDurationDebug
        }
    }
    
    public override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        recorder.stopRecording()
    }
    
    func configureViews() {
        
        let colorScheme = ColorScheme()
        colorScheme.variant = .Light
        
        self.view.backgroundColor = colorScheme.colorWithName(ColorSchemeColorTextForeground)
        
        self.recordTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(recordButtonPressed(_:)))
        self.view.addGestureRecognizer(self.recordTapGestureRecognizer)
        
        self.accentColorChangeHandler = AccentColorChangeHandler.addObserver(self) { [unowned self] color, _ in
            self.audioPreviewView.color = color
        }
        
        [self.audioPreviewView, self.timeLabel, self.tipLabel, self.recordButton, self.stopRecordButton, self.confirmButton, self.redoButton, self.cancelButton, self.tipLabel, self.bottomToolbar, self.topContainer, self.topSeparator].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        
        self.audioPreviewView.gradientWidth = 20
        self.audioPreviewView.gradientColor = colorScheme.colorWithName(ColorSchemeColorTextForeground)
        
        self.topSeparator.backgroundColor = colorScheme.colorWithName(ColorSchemeColorSeparator)
        
        self.createTipLabel()
        
        self.timeLabel.font = UIFont(magicIdentifier: "style.text.small.font_spec_light")
        self.timeLabel.textColor = colorScheme.colorWithName(ColorSchemeColorTextForeground)
        
        [self.audioPreviewView, self.timeLabel, self.tipLabel].forEach(self.topContainer.addSubview)

        self.recordButton.setIcon(.RecordDot, withSize: .Tiny, forState: .Normal)
        self.recordButton.accessibilityLabel = "record"
        self.recordButton.addTarget(self, action: #selector(recordButtonPressed(_:)), forControlEvents: .TouchUpInside)
        self.recordButton.setBackgroundImageColor(UIColor(forZMAccentColor: .VividRed), forState: .Normal)
        self.recordButton.setIconColor(UIColor.whiteColor(), forState: .Normal)
        self.recordButton.layer.masksToBounds = true

        self.stopRecordButton.setIcon(.StopRecording, withSize: .Tiny, forState: .Normal)
        self.stopRecordButton.accessibilityLabel = "stopRecording"
        self.stopRecordButton.addTarget(self, action: #selector(stopRecordButtonPressed(_:)), forControlEvents: .TouchUpInside)
        self.stopRecordButton.setBackgroundImageColor(UIColor(forZMAccentColor: .VividRed), forState: .Normal)
        self.stopRecordButton.setIconColor(UIColor.whiteColor(), forState: .Normal)
        self.stopRecordButton.layer.masksToBounds = true

        self.confirmButton.setIcon(.Checkmark, withSize: .Tiny, forState: .Normal)
        self.confirmButton.accessibilityLabel = "confirmRecording"
        self.confirmButton.addTarget(self, action: #selector(confirmButtonPressed(_:)), forControlEvents: .TouchUpInside)
        self.confirmButton.setBackgroundImageColor(UIColor(forZMAccentColor: .StrongLimeGreen), forState: .Normal)
        self.confirmButton.setIconColor(UIColor.whiteColor(), forState: .Normal)
        self.confirmButton.layer.masksToBounds = true

        self.redoButton.setIcon(.Undo, withSize: .Tiny, forState: .Normal)
        self.redoButton.accessibilityLabel = "redoRecording"
        self.redoButton.addTarget(self, action: #selector(redoButtonPressed(_:)), forControlEvents: .TouchUpInside)
        self.redoButton.setIconColor(UIColor.whiteColor(), forState: .Normal)

        self.cancelButton.setIcon(.Cancel, withSize: .Tiny, forState: .Normal)
        self.cancelButton.accessibilityLabel = "cancelRecording"
        self.cancelButton.addTarget(self, action: #selector(cancelButtonPressed(_:)), forControlEvents: .TouchUpInside)
        self.cancelButton.setIconColor(UIColor.whiteColor(), forState: .Normal)

        [self.recordButton, self.stopRecordButton, self.confirmButton, self.redoButton, self.cancelButton].forEach(self.bottomToolbar.addSubview)
        
        [self.bottomToolbar, self.topContainer, self.topSeparator].forEach(self.view.addSubview)
        
        self.timeLabel.accessibilityLabel = "recordingTime"

        updateRecordingState(self.state)
    }
    
    func createTipLabel() {
        let colorScheme = ColorScheme()
        colorScheme.variant = .Light
        
        let tipText = "conversation.input_bar.audio_message.keyboard.record_tip".localized.uppercaseString
        let attributedTipText = NSMutableAttributedString(string: tipText)
        let atRange = (tipText as NSString).rangeOfString("%@")
        
        if atRange.location != NSNotFound {
            let suitableEffects = AVSAudioEffectType.displayedEffects.filter {
                $0 != .None
            }
            
            let randomEffect = suitableEffects[Int(rand()) % suitableEffects.count]
            let randomEffectImage = UIImage(forIcon: randomEffect.icon, iconSize: .SearchBar, color: colorScheme.colorWithName(ColorSchemeColorTextDimmed))

            let tipEffectImageAttachment = NSTextAttachment()
            tipEffectImageAttachment.image = randomEffectImage
            
            let tipEffectImage = NSAttributedString(attachment: tipEffectImageAttachment)
            
            attributedTipText.replaceCharactersInRange(atRange, withAttributedString: tipEffectImage)
        }
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 8
       
        attributedTipText.addAttribute(NSParagraphStyleAttributeName, value: style, range: NSMakeRange(0, (attributedTipText.string as NSString).length))
        self.tipLabel.attributedText = attributedTipText
        self.tipLabel.numberOfLines = 2
        self.tipLabel.font = UIFont(magicIdentifier: "style.text.small.font_spec_light")
        self.tipLabel.textColor = colorScheme.colorWithName(ColorSchemeColorTextDimmed)
        self.tipLabel.textAlignment = .Center
        
    }
    
    func createConstraints() {
        
        constrain(self.view, self.topContainer, self.bottomToolbar, self.topSeparator) { view, topContainer, bottomToolbar, topSeparator in
            topContainer.left >= view.left + 16
            topContainer.top >= view.top + 16
            topContainer.right <= view.right - 16

            topContainer.left == view.left + 16 ~ 750
            topContainer.top == view.top + 16 ~ 750
            topContainer.right == view.right - 16 ~ 750

            topContainer.width <= 400
            topContainer.centerX == view.centerX
            
            bottomToolbar.top == topContainer.bottom
            bottomToolbar.left == topContainer.left
            bottomToolbar.bottom == view.bottom
            bottomToolbar.right == topContainer.right
            bottomToolbar.height == 72
            bottomToolbar.centerX == topContainer.centerX
            
            topSeparator.height == 0.5
            topSeparator.top == view.top
            topSeparator.left == view.left
            topSeparator.right == view.right
        }
        
        constrain(self.topContainer, self.audioPreviewView, self.timeLabel, self.tipLabel, self.stopRecordButton) { topContainer, audioPreviewView, timeLabel, tipLabel, stopRecordButton in
            
            audioPreviewView.top == topContainer.top + 20
            audioPreviewView.left == topContainer.left + 8
            audioPreviewView.right == topContainer.right - 8
            audioPreviewView.height == 100
            
            timeLabel.centerX == topContainer.centerX
            timeLabel.bottom == stopRecordButton.top - 16
            
            tipLabel.center == topContainer.center
        }
        
        constrain(self.bottomToolbar, self.recordButton, self.stopRecordButton) { bottomToolbar, recordButton, stopRecordButton in
            
            recordButton.center == bottomToolbar.center
            recordButton.width == recordButton.height
            recordButton.height == 40
            
            stopRecordButton.center == bottomToolbar.center
            stopRecordButton.width == stopRecordButton.height
            stopRecordButton.height == 40
        }
        
        constrain(self.bottomToolbar, self.redoButton, self.confirmButton, self.cancelButton) { bottomToolbar, redoButton, confirmButton, cancelButton in
            confirmButton.center == bottomToolbar.center
            confirmButton.width == confirmButton.height
            confirmButton.height == 40
            
            redoButton.centerY == bottomToolbar.centerY
            redoButton.left == bottomToolbar.left + 8
            
            cancelButton.centerY == bottomToolbar.centerY
            cancelButton.right == bottomToolbar.right - 8
        }
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.confirmButton.layer.cornerRadius = self.confirmButton.bounds.size.width / 2
        self.recordButton.layer.cornerRadius = self.recordButton.bounds.size.width / 2
        self.stopRecordButton.layer.cornerRadius = self.stopRecordButton.bounds.size.width / 2
    }
    
    func configureAudioRecorder() {
        recorder.recordTimerCallback = { [weak self] time in
            guard let `self` = self else { return }
            self.updateTimeLabel(time)
        }
        
        recorder.recordStartedCallback = {
            AppDelegate.sharedAppDelegate().mediaPlaybackManager.audioTrackPlayer.stop()
        }
        
        recorder.recordEndedCallback = { [weak self] reachedMaxRecordingDuration in
            guard let `self` = self else { return }
            self.state = .Effects
            if reachedMaxRecordingDuration {
                
                let duration = Int(ceil(self.recorder.maxRecordingDuration ?? 0))
                let (seconds, minutes) = (duration % 60, duration / 60)
                
                let durationLimit = String(format: "%d:%02d", minutes, seconds)
                
                let alertController = UIAlertController(title: "conversation.input_bar.audio_message.too_long.title".localized, message: "conversation.input_bar.audio_message.too_long.message".localized(args: durationLimit), preferredStyle: .Alert)
                let actionCancel = UIAlertAction(title: "general.cancel".localized, style: .Cancel, handler: nil)
                alertController.addAction(actionCancel)
                
                let actionSend = UIAlertAction(title: "conversation.input_bar.audio_message.send".localized, style: .Default, handler: { action in
                    self.sendAudioAsIs(.AfterPreview)
                })
                alertController.addAction(actionSend)
                
                self.presentViewController(alertController, animated: true, completion: .None)
            }
        }
        
        recorder.recordLevelCallBack = { [weak self] level in
            guard let `self` = self else { return }
            self.audioPreviewView.updateWithLevel(CGFloat(level))
        }
    }
    
    func updateTimeLabel(durationInSeconds: NSTimeInterval) {
        let duration = Int(ceil(durationInSeconds))
        let (seconds, minutes) = (duration % 60, duration / 60)
        timeLabel.text = String(format: "%d:%02d", minutes, seconds)
        timeLabel.accessibilityValue = timeLabel.text
    }
    
    private func visibleViews(forState forState: State) -> [UIView] {
        var result = [self.topSeparator, self.topContainer, self.bottomToolbar]
        switch state {
        case .Ready:
            result.appendContentsOf([self.tipLabel, self.recordButton])
        case .Recording:
            result.appendContentsOf([self.audioPreviewView, self.timeLabel, self.stopRecordButton])
        case .Effects:
            result.appendContentsOf([self.redoButton, self.confirmButton, self.cancelButton])
        }
        
        return result
    }
    
    private func updateRecordingState(state: State) {
        let visibleViews = self.visibleViews(forState: state)
        let allViews = Set(view.subviews.flatMap { $0.subviews })
        let hiddenViews = allViews.subtract(visibleViews)
        
        visibleViews.forEach { $0.hidden = false }
        hiddenViews.forEach { $0.hidden = true }
        
        switch state {
        case .Ready:
            self.closeEffectsPicker(animated: false)
            self.recordTapGestureRecognizer.enabled = true
        case .Recording:
            self.closeEffectsPicker(animated: false)
            self.recordTapGestureRecognizer.enabled = false
        case .Effects:
            self.openEffectsPicker()
            self.recordTapGestureRecognizer.enabled = false
        }
    }
    
    func stopAndDeleteRecordingIfNeeded() {
        recorder.stopRecording()
        recorder.deleteRecording()
    }
    
    func sendAudioAsIs(context: AudioMessageContext) {
        recorder.stopPlaying()
        guard let url = recorder.fileURL else { return DDLogWarn("Nil url passed to send as audio file") }
        
        delegate?.audioRecordViewControllerWantsToSendAudio(self, recordingURL: url, duration: recorder.currentDuration, context: context, filter: .None)
    }
    
    private func openEffectsPicker() {
        guard let url = recorder.fileURL else { return DDLogWarn("Nil url passed to add effect to audio file") }

        let noizeReducePath = (NSTemporaryDirectory() as NSString).stringByAppendingPathComponent("noize-reduce.wav")
        noizeReducePath.deleteFileAtPath()
        // To apply noize reduction filter
        AVSAudioEffectType.None.apply(url.path!, outPath: noizeReducePath) {
            self.currentEffectFilePath = noizeReducePath
            url.path!.deleteFileAtPath()
            
            if self.effectPickerViewController != .None {
                self.closeEffectsPicker(animated: false)
            }
            
            let newEffectPickerViewController = AudioEffectsPickerViewController(recordingPath: noizeReducePath, duration: self.recorder.currentDuration)
            newEffectPickerViewController.delegate = self
            self.addChildViewController(newEffectPickerViewController)
            newEffectPickerViewController.view.alpha = 0
            
            UIView.transitionWithView(self.view, duration: 0.35, options: [.CurveEaseIn], animations: {
                newEffectPickerViewController.view.translatesAutoresizingMaskIntoConstraints = false
                self.topContainer.addSubview(newEffectPickerViewController.view)
                constrain(self.topContainer, newEffectPickerViewController.view) { topContainer, newControllerView in
                    topContainer.edges == newControllerView.edges
                }
                newEffectPickerViewController.view.alpha = 1
            }) { _ in
                newEffectPickerViewController.didMoveToParentViewController(self)
            }
            
            self.effectPickerViewController = newEffectPickerViewController
        }
    }
    
    private func closeEffectsPicker(animated animated: Bool) {
        if let picker = self.effectPickerViewController {
            picker.willMoveToParentViewController(nil)
            picker.removeFromParentViewController()
            self.effectPickerViewController = .None
        }
    }
    
    // MARK: - Button actions
    
    internal func recordButtonPressed(sender: AnyObject!) {
        self.state = .Recording
        self.recorder.startRecording()
        self.delegate?.audioRecordViewControllerDidStartRecording(self)
    }
    
    func stopRecordButtonPressed(button: UIButton?) {
        self.recorder.stopRecording()
    }
    
    func confirmButtonPressed(button: UIButton?) {
        
        guard let audioPath = self.currentEffectFilePath else {
            DDLogError("No file to send")
            return
        }
        
        let effectName: String
        
        if self.currentEffect == .None {
            effectName = "Original"
        }
        else {
            effectName = self.currentEffect.description
        }
        
        let filename = (NSString.filenameForSelfUser().stringByAppendingString("-" + effectName) as NSString).stringByAppendingPathExtension("m4a")!
        let convertedPath = (NSTemporaryDirectory() as NSString).stringByAppendingPathComponent(filename)
        convertedPath.deleteFileAtPath()
        
        AVAsset.wr_convertAudioToUploadFormat(audioPath, outPath: convertedPath) { (success) in
            if success {
                audioPath.deleteFileAtPath()
                self.delegate?.audioRecordViewControllerWantsToSendAudio(self, recordingURL: NSURL(fileURLWithPath: convertedPath), duration: self.recorder.currentDuration, context: .AfterEffect, filter: self.currentEffect)
            }
        }
    }
    
    func redoButtonPressed(button: UIButton?) {
        self.state = .Ready
    }
    
    func cancelButtonPressed(button: UIButton?) {
        self.delegate?.audioRecordViewControllerDidCancel(self)
    }
}

extension AudioRecordKeyboardViewController: AudioEffectsPickerDelegate {
    public func audioEffectsPickerDidPickEffect(picker: AudioEffectsPickerViewController, effect: AVSAudioEffectType, resultFilePath: String) {
        self.currentEffectFilePath = resultFilePath
        self.currentEffect = effect
    }
}
