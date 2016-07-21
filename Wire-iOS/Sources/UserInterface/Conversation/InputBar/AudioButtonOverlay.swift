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


@objc public final class AudioButtonOverlay: UIView {
    
    enum AudioButtonOverlayButtonType {
        case Play, Send, Stop
    }
    
    typealias ButtonPressHandler = AudioButtonOverlayButtonType -> Void
    
    var recordingState: AudioRecordState = .Recording {
        didSet { updateWithRecordingState(recordingState) }
    }
    
    var playingState: PlayingState = .Idle {
        didSet { updateWithPlayingState(playingState) }
    }
    
    private var heightConstraint: NSLayoutConstraint?
    private var widthConstraint: NSLayoutConstraint?
    
    var iconColor, iconColorHighlighted, greenColor, grayColor, superviewColor: UIColor?
    
    let audioButton = IconButton()
    let playButton = IconButton()
    let sendButton = IconButton()
    let backgroundView = UIView()
    var buttonHandler: ButtonPressHandler?
    
    init() {
        super.init(frame: CGRectZero)
        CASStyler.defaultStyler().styleItem(self)
        configureViews()
        createConstraints()
        updateWithRecordingState(recordingState)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        backgroundView.layer.cornerRadius = bounds.width / 2
    }

    func configureViews() {
        translatesAutoresizingMaskIntoConstraints = false
        audioButton.userInteractionEnabled = false
        audioButton.setIcon(.Microphone, withSize: .Tiny, forState: .Normal)
        audioButton.accessibilityIdentifier = "audioRecorderRecord"
        
        playButton.setIcon(.Play, withSize: .Tiny, forState: .Normal)
        playButton.accessibilityIdentifier = "audioRecorderPlay"
        playButton.accessibilityValue = PlayingState.Idle.description

        sendButton.setIcon(.Checkmark, withSize: .Tiny, forState: .Normal)
        sendButton.accessibilityIdentifier = "audioRecorderSend"
        
        [backgroundView, audioButton, sendButton, playButton].forEach(addSubview)
        
        playButton.addTarget(self, action: #selector(buttonPressed), forControlEvents: .TouchUpInside)
        sendButton.addTarget(self, action: #selector(buttonPressed), forControlEvents: .TouchUpInside)
    }
    
    func createConstraints() {
        let initialViewWidth: CGFloat = 40
        
        constrain(self, audioButton, playButton, sendButton, backgroundView) { view, audioButton, playButton, sendButton, backgroundView in
            audioButton.centerY == view.bottom - initialViewWidth / 2
            audioButton.centerX == view.centerX
            
            playButton.centerX == view.centerX
            playButton.centerY == view.bottom - initialViewWidth / 2
            
            sendButton.centerX == view.centerX
            sendButton.centerY == view.top + initialViewWidth / 2
            
            widthConstraint = view.width == initialViewWidth
            heightConstraint = view.height == 96
            backgroundView.edges == view.edges
        }
    }
    
    func setOverlayState(state: AudioButtonOverlayState) {
        defer { layoutIfNeeded() }
        heightConstraint?.constant = state.height
        widthConstraint?.constant = state.width
        alpha = state.alpha
        
        guard let greenColor = greenColor, grayColor = grayColor, darkColor = iconColor,
            brightColor = iconColorHighlighted, superviewColor = superviewColor else { return }
        
        let blendedGray = grayColor.removeAlphaByBlendingWithColor(superviewColor)
        sendButton.setIconColor(state.colorWithColors(greenColor, highlightedColor: brightColor), forState: .Normal)
        backgroundView.backgroundColor = state.colorWithColors(blendedGray, highlightedColor: greenColor)
        audioButton.setIconColor(state.colorWithColors(darkColor, highlightedColor: brightColor), forState: .Normal)
        playButton.setIconColor(darkColor, forState: .Normal)
    }
    
    func updateWithRecordingState(state: AudioRecordState) {
        audioButton.hidden = state == .FinishedRecording
        playButton.hidden = state == .Recording
        sendButton.hidden = false
        backgroundView.hidden = false
    }
    
    func updateWithPlayingState(state: PlayingState) {
        let icon: ZetaIconType = state == .Idle ? .Play : .Stop
        playButton.setIcon(icon, withSize: .Tiny, forState: .Normal)
        playButton.accessibilityValue = state.description
    }
    
    func buttonPressed(sender: IconButton) {
        let type: AudioButtonOverlayButtonType
        
        if sender == sendButton {
            type = .Send
        } else {
            type = playingState == .Idle ? .Play : .Stop
        }
        
        buttonHandler?(type)
    }
    
}
