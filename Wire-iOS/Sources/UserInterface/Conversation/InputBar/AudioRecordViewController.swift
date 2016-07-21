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
import MobileCoreServices

@objc public protocol AudioRecordBaseViewController: NSObjectProtocol {
    weak var delegate: AudioRecordViewControllerDelegate? { get set }
}

@objc public protocol AudioRecordViewControllerDelegate: class {
    func audioRecordViewControllerDidCancel(audioRecordViewController: AudioRecordBaseViewController)
    func audioRecordViewControllerDidStartRecording(audioRecordViewController: AudioRecordBaseViewController)
    func audioRecordViewControllerWantsToSendAudio(audioRecordViewController: AudioRecordBaseViewController, recordingURL: NSURL, duration: NSTimeInterval, context: AudioMessageContext, filter: AVSAudioEffectType)
}


@objc enum AudioRecordState: UInt {
    case Recording, FinishedRecording
}


@objc public enum AudioMessageContext: UInt {
    case AfterSlideUp, AfterPreview, AfterEffect
}

private let margin = (CGFloat(WAZUIMagic.floatForIdentifier("content.left_margin")) / 2) - (UIImage.sizeForZetaIconSize(.Tiny) / 2)


@objc public final class AudioRecordViewController: UIViewController, AudioRecordBaseViewController {
    
    let buttonOverlay = AudioButtonOverlay()
    let topSeparator = UIView()
    let rightSeparator = UIView()
    let topTooltipLabel = UILabel()
    let timeLabel = UILabel()
    let audioPreviewView = WaveFormView()
    var accentColorChangeHandler: AccentColorChangeHandler?
    let bottomContainerView = UIView()
    let topContainerView = UIView()
    let cancelButton = IconButton()
    let recordingDotView = RecordingDotView()
    var recordingDotViewVisible: ConstraintGroup?
    var recordingDotViewHidden: ConstraintGroup?
    
    public let recorder = AudioRecorder(format: .WAV, maxRecordingDuration: 25.0 * 60.0)! // 25 Minutes
    
    weak public var delegate: AudioRecordViewControllerDelegate?
    
    var recordingState: AudioRecordState = .Recording {
        didSet { updateRecordingState(recordingState) }
    }
    
    private let localizationBasePath = "conversation.input_bar.audio_message"
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init() {
        super.init(nibName: nil, bundle: nil)
        configureViews()
        configureAudioRecorder()
        createConstraints()

        if DeveloperMenuState.developerMenuEnabled() && Settings.sharedSettings().maxRecordingDurationDebug != 0 {
            self.recorder.maxRecordingDuration = Settings.sharedSettings().maxRecordingDurationDebug
        }
    }
    
    deinit {
        stopAndDeleteRecordingIfNeeded()
        accentColorChangeHandler = nil
    }
    
    func beginRecording() {
        self.delegate?.audioRecordViewControllerDidStartRecording(self)
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        delay(0.25) {
            self.recorder.startRecording()
        }
    }
    
    func finishRecordingIfNeeded(sender: UIGestureRecognizer) {
        let location = sender.locationInView(buttonOverlay)
        let upperThird = location.y < CGRectGetHeight(buttonOverlay.frame) / 3
        let shouldSend = upperThird && sender.state == .Ended
        
        guard recorder.stopRecording() else { return DDLogWarn("Stopped recording but did not get file URL") }
        
        if shouldSend {
            sendAudio(.AfterSlideUp)
        }
    }
    
    func updateWithChangedRecognizer(sender: UIGestureRecognizer) {
        let height = buttonOverlay.frame.height
        let (topOffset, mixRange) = (height / 4, height / 2)
        let locationY = sender.locationInView(buttonOverlay).y - topOffset
        let offset: CGFloat = locationY < mixRange ? 1 - locationY / mixRange : 0

        setOverlayState(.Expanded(offset.clamp(0, upper: 1)), animated: false)
    }
    
    func configureViews() {
        accentColorChangeHandler = AccentColorChangeHandler.addObserver(self) { [unowned self] color, _ in
            self.audioPreviewView.color = color
        }
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(topContainerTapped))
        topContainerView.addGestureRecognizer(tapRecognizer)
        
        topContainerView.addSubview(topTooltipLabel)
        [bottomContainerView, topContainerView, buttonOverlay].forEach(view.addSubview)
        [topSeparator, rightSeparator, audioPreviewView, timeLabel, cancelButton, recordingDotView].forEach(bottomContainerView.addSubview)
        
        timeLabel.accessibilityLabel = "audioRecorderTimeLabel"
        
        topTooltipLabel.text = "conversation.input_bar.audio_message.tooltip.pull_send".localized.uppercaseString
        topTooltipLabel.accessibilityLabel = "audioRecorderTopTooltipLabel"
        
        cancelButton.setIcon(.Cancel, withSize: .Tiny, forState: .Normal)
        cancelButton.addTarget(self, action: #selector(cancelButtonPressed(_:)), forControlEvents: .TouchUpInside)
        cancelButton.accessibilityLabel = "audioRecorderCancel"
        updateRecordingState(recordingState)
        CASStyler.defaultStyler().styleItem(self)
        
        buttonOverlay.buttonHandler = { [weak self] buttonType in
            guard let `self` = self else {
                return
            }
            switch buttonType {
            case .Send: self.sendAudio(.AfterPreview)
            case .Play:
                Analytics.shared()?.tagPreviewedAudioMessageRecording(.Minimised)
                self.recorder.playRecording()
            case .Stop: self.recorder.stopPlaying()
            }
        }
    }
    
    func createConstraints() {
        let button = buttonOverlay.audioButton

        constrain(view, bottomContainerView, topContainerView, button) { view, bottomContainer, topContainer, overlayButton in
            bottomContainer.height == 56
            bottomContainer.left == view.left
            bottomContainer.right == view.right
            bottomContainer.bottom == view.bottom
            
            overlayButton.centerY == bottomContainer.centerY
            
            topContainer.left == view.left
            topContainer.top == view.top
            topContainer.right == view.right
            topContainer.bottom == bottomContainer.top
        }
        
        constrain(topContainerView, topTooltipLabel, buttonOverlay) { topContainer, topTooltip, overlay in
            topContainer.centerY == topTooltip.centerY
            topTooltip.right == overlay.left - 12
        }
        
        constrain(bottomContainerView, buttonOverlay, topSeparator) { container, overlay, separator in
            separator.height == 0.5
            separator.right == overlay.left - 8
            separator.left == container.left + 16
            separator.top == container.top
        }
        
        self.recordingDotViewHidden = constrain(bottomContainerView, timeLabel) { container, timeLabel in
            timeLabel.centerY == container.centerY
            timeLabel.left == container.left + margin
        }
        
        self.recordingDotViewHidden?.active = false
        
        self.recordingDotViewVisible = constrain(bottomContainerView, timeLabel, recordingDotView) { container, timeLabel, recordingDotView in
            
            timeLabel.centerY == container.centerY
            timeLabel.left == recordingDotView.right + 24
            
            recordingDotView.width == recordingDotView.height
            recordingDotView.width == 8
            
            recordingDotView.left == container.left + margin + 8
            recordingDotView.centerY == container.centerY
        }
        self.recordingDotViewVisible?.active = true
        
        
        constrain(bottomContainerView, buttonOverlay, rightSeparator) { container, overlay, rightSeparator in
            rightSeparator.right == container.right
            rightSeparator.left == overlay.right + 8
            rightSeparator.top == container.top
            rightSeparator.height == 0.5
        }
        
        constrain(bottomContainerView, timeLabel, audioPreviewView, cancelButton, buttonOverlay) { container, timeLabel, previewView, cancelButton, overlay in
            previewView.left == timeLabel.right + 8
            previewView.top == container.top + 12
            previewView.bottom == container.bottom - 12
            previewView.right == overlay.left - 12

            cancelButton.centerY == container.centerY
            cancelButton.right == container.right
            cancelButton.width == cancelButton.height
            cancelButton.width == 56
            overlay.right == cancelButton.left - 12
        }
    }
    
    func configureAudioRecorder() {
        recorder.recordTimerCallback = { [weak self] time in
            guard let `self` = self else {
                return
            }
            self.updateTimeLabel(time)
        }
        
        recorder.recordStartedCallback = {
            AppDelegate.sharedAppDelegate().mediaPlaybackManager.audioTrackPlayer.stop()
        }
        
        recorder.recordEndedCallback = { [weak self] reachedMaxRecordingDuration in
            guard let `self` = self else {
                return
            }
            self.recordingState = .FinishedRecording
            if reachedMaxRecordingDuration {
                
                let duration = Int(ceil(self.recorder.maxRecordingDuration ?? 0))
                let (seconds, minutes) = (duration % 60, duration / 60)
                
                let durationLimit = String(format: "%d:%02d", minutes, seconds)
                
                let alertController = UIAlertController(title: "conversation.input_bar.audio_message.too_long.title".localized, message: "conversation.input_bar.audio_message.too_long.message".localized(args: durationLimit), preferredStyle: .Alert)
                let actionCancel = UIAlertAction(title: "general.cancel".localized, style: .Cancel, handler: nil)
                alertController.addAction(actionCancel)
                
                let actionSend = UIAlertAction(title: "conversation.input_bar.audio_message.send".localized, style: .Default, handler: { action in
                    self.sendAudio(.AfterPreview)
                })
                alertController.addAction(actionSend)
                
                self.presentViewController(alertController, animated: true, completion: .None)
            }
        }
        
        recorder.playingStateCallback = { [weak self] state in
            guard let `self` = self else {
                return
            }
            self.buttonOverlay.playingState = state
        }
        
        recorder.recordLevelCallBack = { [weak self] level in
            guard let `self` = self else {
                return
            }
            self.audioPreviewView.updateWithLevel(CGFloat(level))
        }
    }
    
    func topContainerTapped(sender: UITapGestureRecognizer) {
        delegate?.audioRecordViewControllerDidCancel(self)
    }
    
    func setRecordingState(state: AudioRecordState, animated: Bool) {
        updateRecordingState(state)
        
        if animated {
            UIView.animateWithDuration(0.2) {
                self.view.layoutIfNeeded()
            }
        }
    }
    
    func updateRecordingState(state: AudioRecordState) {
        
        let visible = visibleViewsForState(state)
        let allViews = Set(view.subviews.flatMap { $0.subviews }) // Well, 2 levels 'all'
        let hidden = allViews.subtract(visible)
        
        visible.forEach { $0.hidden = false }
        hidden.forEach { $0.hidden = true }
        
        buttonOverlay.recordingState = state
        let finished = state == .FinishedRecording
        
        self.recordingDotView.animating = !finished
        
        let pathComponent = finished ? "tooltip.tap_send" : "tooltip.pull_send"
        topTooltipLabel.text = "\(localizationBasePath).\(pathComponent)".localized.uppercaseString
        
        if self.recordingState == .Recording {
            self.recordingDotViewHidden?.active = false
            self.recordingDotViewVisible?.active = true
        }
        else {
            self.recordingDotViewVisible?.active = false
            self.recordingDotViewHidden?.active = true
        }
    }
    
    func updateTimeLabel(durationInSeconds: NSTimeInterval) {
        let duration = Int(ceil(durationInSeconds))
        let (seconds, minutes) = (duration % 60, duration / 60)
        timeLabel.text = String(format: "%d:%02d", minutes, seconds)
        timeLabel.accessibilityValue = timeLabel.text
    }
    
    func visibleViewsForState(state: AudioRecordState) -> [UIView] {
        var visibleViews = [bottomContainerView, topContainerView, buttonOverlay, topSeparator, timeLabel, audioPreviewView, topTooltipLabel]
        
        switch state {
        case .FinishedRecording:
            visibleViews.append(cancelButton)
        case .Recording:
            visibleViews.append(recordingDotView)
        }
        
        if traitCollection.userInterfaceIdiom == .Pad { visibleViews.append(rightSeparator) }
        
        return visibleViews
    }
    
    func setOverlayState(state: AudioButtonOverlayState, animated: Bool) {
        let animations = { self.buttonOverlay.setOverlayState(state) }
        
        if state.animatable && animated {
            UIView.animateWithDuration(
                state.duration,
                delay: 0,
                usingSpringWithDamping: state.springDampening,
                initialSpringVelocity: state.springVelocity,
                options: .CurveEaseOut,
                animations: animations,
                completion: nil
            )
        } else {
            animations()
        }
    }
    
    func cancelButtonPressed(sender: IconButton) {
        Analytics.shared()?.tagCancelledAudioMessageRecording()
        
        recorder.stopPlaying()
        stopAndDeleteRecordingIfNeeded()
        delegate?.audioRecordViewControllerDidCancel(self)
        updateTimeLabel(0)
    }
    
    func stopAndDeleteRecordingIfNeeded() {
        recorder.stopRecording()
        recorder.deleteRecording()
    }
    
    func sendAudio(context: AudioMessageContext) {
        recorder.stopPlaying()
        guard let url = recorder.fileURL else { return DDLogWarn("Nil url passed to send as audio file") }
        
        
        let effectPath = (NSTemporaryDirectory() as NSString).stringByAppendingPathComponent("effect.wav")
        effectPath.deleteFileAtPath()
        // To apply noize reduction filter
        AVSAudioEffectType.None.apply(url.path!, outPath: effectPath) {
            url.path!.deleteFileAtPath()
            
            let filename = (NSString.filenameForSelfUser() as NSString).stringByAppendingPathExtension("m4a")!
            let convertedPath = (NSTemporaryDirectory() as NSString).stringByAppendingPathComponent(filename)
            convertedPath.deleteFileAtPath()
            
            AVAsset.wr_convertAudioToUploadFormat(effectPath, outPath: convertedPath) { success in
                effectPath.deleteFileAtPath()
                
                if success {
                    self.delegate?.audioRecordViewControllerWantsToSendAudio(self, recordingURL: NSURL(fileURLWithPath: convertedPath), duration: self.recorder.currentDuration, context: context, filter: .None)
                }
            }
        }
        
    }

}
