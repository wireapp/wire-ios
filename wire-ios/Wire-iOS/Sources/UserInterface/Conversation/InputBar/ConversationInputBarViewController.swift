// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

import MobileCoreServices
import Photos
import UIKit
import WireSyncEngine
import avs
import AVFoundation

enum ConversationInputBarViewControllerMode {
    case textInput
    case audioRecord
    case camera
    case timeoutConfguration
}

final class ConversationInputBarViewController: UIViewController,
                                                UIPopoverPresentationControllerDelegate,
                                                PopoverPresenter {

    let mediaShareRestrictionManager = MediaShareRestrictionManager(sessionRestriction: ZMUserSession.shared())

    // MARK: PopoverPresenter
    var presentedPopover: UIPopoverPresentationController?
    var popoverPointToView: UIView?

    typealias ButtonColors = SemanticColors.Button

    let conversation: InputBarConversationType
    weak var delegate: ConversationInputBarViewControllerDelegate?

    private let classificationProvider: ClassificationProviding?

    private(set) var inputController: UIViewController? {
        willSet {
            inputController?.view.removeFromSuperview()
        }

        didSet {
            deallocateUnusedInputControllers()

            defer {
                inputBar.textView.reloadInputViews()
            }

            guard let inputController = inputController else {
                inputBar.textView.inputView = nil
                return
            }

            let inputViewSize = UIView.lastKeyboardSize

            let inputViewFrame: CGRect = CGRect(origin: .zero, size: inputViewSize)
            let inputView = UIInputView(frame: inputViewFrame, inputViewStyle: .keyboard)
            inputView.allowsSelfSizing = true

            inputView.autoresizingMask = .flexibleWidth
            inputController.view.frame = inputView.frame
            inputController.view.autoresizingMask = .flexibleWidth
            if let view = inputController.view {
                inputView.addSubview(view)
            }

            inputBar.textView.inputView = inputView
        }
    }

    var mentionsHandler: MentionsHandler?
    weak var mentionsView: (Dismissable & UserList & KeyboardCollapseObserver)?

    var textfieldObserverToken: Any?
    lazy var audioSession: AVAudioSessionType = AVAudioSession.sharedInstance()

    // MARK: buttons
    let photoButton: IconButton = {
        let button = IconButton()
        button.setIconColor(UIColor.accent(), for: UIControl.State.selected)
        return button
    }()

    lazy var ephemeralIndicatorButton: IconButton = {
        let button = IconButton(fontSpec: .smallSemiboldFont)
        button.layer.borderWidth = 0.5

        button.accessibilityIdentifier = "ephemeralTimeIndicatorButton"
        button.adjustsTitleWhenHighlighted = true
        button.adjustsBorderColorWhenHighlighted = true

        button.setTitleColor(UIColor.lightGraphite, for: .disabled)
        button.setTitleColor(UIColor.accent(), for: .normal)

        configureEphemeralKeyboardButton(button)

        return button
    }()

    lazy var hourglassButton: IconButton = {
        let button = IconButton(style: .default)

        button.setIcon(.hourglass, size: .tiny, for: UIControl.State.normal)
        button.accessibilityIdentifier = "ephemeralTimeSelectionButton"

        configureEphemeralKeyboardButton(button)

        return button
    }()

    let markdownButton: IconButton = {
        let button = IconButton()
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true

        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        return button
    }()
    let mentionButton: IconButton = IconButton()
    lazy var audioButton: IconButton = {
        let button = IconButton()
        button.setIconColor(UIColor.accent(), for: .selected)

        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(audioButtonLongPressed(_:)))
        longPressRecognizer.minimumPressDuration = 0.3
        button.addGestureRecognizer(longPressRecognizer)

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(audioButtonPressed(_:)))
        tapGestureRecognizer.require(toFail: longPressRecognizer)
        button.addGestureRecognizer(tapGestureRecognizer)

        return button
    }()

    let uploadFileButton: IconButton = IconButton()
    let sketchButton: IconButton = IconButton()
    let pingButton: IconButton = IconButton()
    let locationButton: IconButton = IconButton()
    let gifButton: IconButton = IconButton()
    let sendButton: IconButton = {
        let button = IconButton.sendButton()
        button.hitAreaPadding = CGSize(width: 30, height: 30)

        return button
    }()

    let videoButton: IconButton = IconButton()

    // MARK: subviews
    lazy var inputBar: InputBar = {
        let inputBar = InputBar(buttons: inputBarButtons)
        if !mediaShareRestrictionManager.canUseSpellChecking {
            inputBar.textView.spellCheckingType = .no
        }
        if !mediaShareRestrictionManager.canUseAutoCorrect {
            inputBar.textView.autocorrectionType = .no
        }
        return inputBar
    }()

    lazy var typingIndicatorView: TypingIndicatorView = {
        let view = TypingIndicatorView()
        view.accessibilityIdentifier = "typingIndicator"
        view.typingUsers = conversation.typingUsers
        view.setHidden(true, animated: false)
        return view
    }()

    private let securityLevelView = SecurityLevelView()

    // MARK: custom keyboards
    var audioRecordViewController: AudioRecordViewController?
    var audioRecordViewContainer: UIView?
    var audioRecordKeyboardViewController: AudioRecordKeyboardViewController?

    var cameraKeyboardViewController: CameraKeyboardViewController?
    var ephemeralKeyboardViewController: EphemeralKeyboardViewController?

    // MARK: text input
    lazy var sendController: ConversationInputBarSendController = {
        return ConversationInputBarSendController(conversation: conversation)
    }()

    var editingMessage: ZMConversationMessage?
    var quotedMessage: ZMConversationMessage?
    var replyComposingView: ReplyComposingView?

    // MARK: feedback
    lazy var impactFeedbackGenerator: UIImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    private lazy var notificationFeedbackGenerator: UINotificationFeedbackGenerator = UINotificationFeedbackGenerator()

    var shouldRefocusKeyboardAfterImagePickerDismiss = false
    // Counter keeping track of calls being made when the audio keyboard ewas visible before.
    var callCountWhileCameraKeyboardWasVisible = 0
    var callStateObserverToken: Any?
    var wasRecordingBeforeCall = false
    let sendButtonState: ConversationInputBarButtonState = ConversationInputBarButtonState()
    var inRotation = false

    private var singleTapGestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer()
    private var conversationObserverToken: Any?
    private var userObserverToken: Any?
    private var typingObserverToken: Any?

    private var inputBarButtons: [IconButton] {
        var buttonsArray: [IconButton] = []
        switch mediaShareRestrictionManager.level {
        case .none:
            buttonsArray = [
                mentionButton,
                photoButton,
                sketchButton,
                gifButton,
                audioButton,
                pingButton,
                uploadFileButton,
                locationButton,
                videoButton
            ]
        case .securityFlag:
            buttonsArray = [
                photoButton,
                mentionButton,
                sketchButton,
                audioButton,
                pingButton,
                locationButton,
                videoButton
            ]
        case .APIFlag:
            buttonsArray = [
                mentionButton,
                pingButton,
                locationButton
            ]
        }
        if !conversation.isSelfDeletingMessageSendingDisabled {
            buttonsArray.insert(hourglassButton, at: buttonsArray.startIndex)
        }

        return buttonsArray
    }

    var mode: ConversationInputBarViewControllerMode = .textInput {
        didSet {
            guard oldValue != mode else {
                return
            }

            let singleTapGestureRecognizerEnabled: Bool
            let selectedButton: IconButton?

            func config(viewController: UIViewController?,
                        setupClosure: () -> UIViewController) {
                if inputController == nil ||
                    inputController != viewController {

                    let newViewController: UIViewController

                    if let viewController = viewController {
                        newViewController = viewController
                    } else {
                        newViewController = setupClosure()
                    }

                    inputController = newViewController
                }
            }

            switch mode {
            case .textInput:
                inputController = nil
                singleTapGestureRecognizerEnabled = false
                selectedButton = nil
            case .audioRecord:
                clearTextInputAssistentItemIfNeeded()
                config(viewController: audioRecordKeyboardViewController) {
                    let audioRecordKeyboardViewController = AudioRecordKeyboardViewController()
                    audioRecordKeyboardViewController.delegate = self
                    self.audioRecordKeyboardViewController = audioRecordKeyboardViewController

                    return audioRecordKeyboardViewController
                }
                singleTapGestureRecognizerEnabled = true
                selectedButton = audioButton
            case .camera:
                clearTextInputAssistentItemIfNeeded()
                config(viewController: cameraKeyboardViewController) {
                    return self.createCameraKeyboardViewController()
                }
                singleTapGestureRecognizerEnabled = true
                selectedButton = photoButton
            case .timeoutConfguration:
                clearTextInputAssistentItemIfNeeded()
                config(viewController: ephemeralKeyboardViewController) {
                    return self.createEphemeralKeyboardViewController()
                }
                singleTapGestureRecognizerEnabled = true
                selectedButton = hourglassButton
            }

            singleTapGestureRecognizer.isEnabled = singleTapGestureRecognizerEnabled
            selectInputControllerButton(selectedButton)

            updateRightAccessoryView()
        }
    }

    // MARK: - Input views handling

    /// init with a InputBarConversationType object
    /// - Parameter conversation: provide nil only for tests
    init(
        conversation: InputBarConversationType,
        classificationProvider: ClassificationProviding? = ZMUserSession.shared()
    ) {
        self.conversation = conversation
        self.classificationProvider = classificationProvider

        super.init(nibName: nil, bundle: nil)

        if !ProcessInfo.processInfo.isRunningTests,
           let conversation = conversation as? ZMConversation {
            conversationObserverToken = ConversationChangeInfo.add(observer: self, for: conversation)
            typingObserverToken = conversation.addTypingObserver(self)
        }

        setupNotificationCenter()
        setupInputLanguageObserver()
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - view life cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupCallStateObserver()

        setupSingleTapGestureRecognizer()

        if conversation.hasDraftMessage,
           let draftMessage = conversation.draftMessage {
            inputBar.textView.setDraftMessage(draftMessage)
        }

        configureMarkdownButton()
        configureMentionButton()

        sendButton.addTarget(self, action: #selector(sendButtonPressed(_:)), for: .touchUpInside)
        photoButton.addTarget(self, action: #selector(cameraButtonPressed(_:)), for: .touchUpInside)
        videoButton.addTarget(self, action: #selector(videoButtonPressed(_:)), for: .touchUpInside)
        sketchButton.addTarget(self, action: #selector(sketchButtonPressed(_:)), for: .touchUpInside)
        uploadFileButton.addTarget(self, action: #selector(docUploadPressed(_:)), for: .touchUpInside)
        pingButton.addTarget(self, action: #selector(pingButtonPressed(_:)), for: .touchUpInside)
        gifButton.addTarget(self, action: #selector(giphyButtonPressed(_:)), for: .touchUpInside)
        locationButton.addTarget(self, action: #selector(locationButtonPressed(_:)), for: .touchUpInside)

        updateAccessoryViews()
        updateInputBarVisibility()
        updateTypingIndicator()
        updateWritingState(animated: false)
        updateButtonIcons()
        updateAvailabilityPlaceholder()
        updateClassificationBanner()

        setInputLanguage()
        setupStyle()

        let interaction = UIDropInteraction(delegate: self)
        inputBar.textView.addInteraction(interaction)

        setupObservers()
    }

    private func setupObservers() {
        guard !ProcessInfo.processInfo.isRunningTests else {
            return
        }

        if conversationObserverToken == nil,
           let conversation = conversation as? ZMConversation {
            conversationObserverToken = ConversationChangeInfo.add(observer: self, for: conversation)
        }

        if let connectedUser = conversation.connectedUserType as? ZMUser,
           let userSession = ZMUserSession.shared() {
            userObserverToken = UserChangeInfo.add(observer: self, for: connectedUser, in: userSession)
        }

        NotificationCenter.default.addObserver(forName: .featureDidChangeNotification,
                                               object: nil,
                                               queue: .main) { [weak self] note in
            guard let change = note.object as? FeatureService.FeatureChange else { return }

            switch change {
            case .fileSharingEnabled, .fileSharingDisabled:
                self?.updateInputBarButtons()

            default:
                break
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateRightAccessoryView()
        inputBar.updateReturnKey()
        inputBar.updateEphemeralState()
        updateMentionList()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        inputBar.textView.endEditing(true)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        endEditingMessageIfNeeded()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        ephemeralIndicatorButton.layer.cornerRadius = ephemeralIndicatorButton.bounds.width / 2
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator?) {

        guard let coordinator = coordinator else { return }

        super.viewWillTransition(to: size, with: coordinator)
        self.inRotation = true

        coordinator.animate(alongsideTransition: nil) { _ in
            self.inRotation = false
            self.updatePopoverSourceRect()
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if traitCollection.userInterfaceStyle != previousTraitCollection?.userInterfaceStyle {
            updateMarkdownButton()
            inputBar.updateColors()
        }

        guard traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass else { return }

        guard !inRotation else { return }

        updatePopoverSourceRect()
    }

    // MARK: - setup
    private func setupStyle() {
        ephemeralIndicatorButton.borderWidth = 0
        hourglassButton.layer.borderWidth = 1
        hourglassButton.setIconColor(SemanticColors.Button.textInputBarItemEnabled, for: .normal)
        hourglassButton.setBackgroundImageColor(SemanticColors.Button.backgroundInputBarItemEnabled, for: .normal)
        hourglassButton.setBorderColor(SemanticColors.Button.borderInputBarItemEnabled, for: .normal)

    }

    private func setupSingleTapGestureRecognizer() {
        singleTapGestureRecognizer.addTarget(self, action: #selector(onSingleTap(_:)))
        singleTapGestureRecognizer.isEnabled = false
        singleTapGestureRecognizer.delegate = self
        singleTapGestureRecognizer.cancelsTouchesInView = true
        view.addGestureRecognizer(singleTapGestureRecognizer)
    }

    func updateRightAccessoryView() {
        updateEphemeralIndicatorButtonTitle(ephemeralIndicatorButton)

        let trimmed = inputBar.textView.text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

        sendButtonState.update(textLength: trimmed.count,
                               editing: nil != editingMessage,
                               markingDown: inputBar.isMarkingDown,
                               destructionTimeout: conversation.activeMessageDestructionTimeoutValue,
                               mode: mode,
                               syncedMessageDestructionTimeout: conversation.hasSyncedMessageDestructionTimeout,
                               isEphemeralSendingDisabled: conversation.isSelfDeletingMessageSendingDisabled,
                               isEphemeralTimeoutForced: conversation.isSelfDeletingMessageTimeoutForced)

        sendButton.isEnabled = sendButtonState.sendButtonEnabled
        sendButton.isHidden = sendButtonState.sendButtonHidden
        ephemeralIndicatorButton.isHidden = sendButtonState.ephemeralIndicatorButtonHidden
        ephemeralIndicatorButton.isEnabled = sendButtonState.ephemeralIndicatorButtonEnabled

        ephemeralIndicatorButton.setBackgroundImage(conversation.timeoutImage, for: .normal)
        ephemeralIndicatorButton.setBackgroundImage(conversation.disabledTimeoutImage, for: .disabled)
    }

    func updateMentionList() {
        triggerMentionsIfNeeded(from: inputBar.textView)
    }

    func clearInputBar() {
        inputBar.textView.text = ""
        inputBar.markdownView.resetIcons()
        inputBar.textView.resetMarkdown()
        updateRightAccessoryView()
        conversation.setIsTyping(false)
        replyComposingView?.removeFromSuperview()
        replyComposingView = nil
        quotedMessage = nil
    }

    func updateNewButtonTitleLabel() {
        photoButton.titleLabel?.isHidden = inputBar.textView.isFirstResponder
    }

    func updateAccessoryViews() {
        updateRightAccessoryView()
    }

    func updateAvailabilityPlaceholder() {
        guard ZMUser.selfUser().hasTeam,
              conversation.conversationType == .oneOnOne,
              let connectedUser = conversation.connectedUserType else {
                  return
              }

        inputBar.availabilityPlaceholder = AvailabilityStringBuilder.string(for: connectedUser, with: .placeholder, color: inputBar.placeholderColor)
    }

    func updateInputBarVisibility() {
        view.isHidden = conversation.isReadOnly
    }

    @objc func updateInputBarButtons() {
        inputBar.buttonsView.buttons = inputBarButtons
        inputBarButtons.forEach {
            $0.setIconColor(SemanticColors.Icon.foregroundDefaultBlack, for: .normal)
        }
        inputBar.buttonsView.setNeedsLayout()
    }

    // MARK: - Security Banner

    private func updateClassificationBanner() {
        securityLevelView.configure(with: conversation.participants, provider: classificationProvider)
    }

    // MARK: - Save draft message
    func draftMessage(from textView: MarkdownTextView) -> DraftMessage {
        let (text, mentions) = textView.preparedText

        return DraftMessage(text: text, mentions: mentions, quote: quotedMessage as? ZMMessage)
    }

    private func didEnterBackground() {
        if !inputBar.textView.text.isEmpty {
            conversation.setIsTyping(false)
        }

        let draft = draftMessage(from: inputBar.textView)
        delegate?.conversationInputBarViewControllerDidComposeDraft(message: draft)
    }

    private func updateButtonIcons() {
        audioButton.setIcon(.microphone, size: .tiny, for: .normal)
        videoButton.setIcon(.videoMessage, size: .tiny, for: .normal)
        photoButton.setIcon(.cameraLens, size: .tiny, for: .normal)
        uploadFileButton.setIcon(.paperclip, size: .tiny, for: .normal)
        sketchButton.setIcon(.brush, size: .tiny, for: .normal)
        pingButton.setIcon(.ping, size: .tiny, for: .normal)
        locationButton.setIcon(.locationPin, size: .tiny, for: .normal)
        gifButton.setIcon(.gif, size: .tiny, for: .normal)
        mentionButton.setIcon(.mention, size: .tiny, for: .normal)
        sendButton.setIcon(.send, size: .tiny, for: .normal)
        sendButton.setIcon(.send, size: .tiny, for: .disabled)
    }

    func selectInputControllerButton(_ button: IconButton?) {
        for otherButton in [photoButton, audioButton, hourglassButton] {
            otherButton.isSelected = button == otherButton
        }
    }

    func clearTextInputAssistentItemIfNeeded() {
        let item = inputBar.textView.inputAssistantItem
        item.leadingBarButtonGroups = []
        item.trailingBarButtonGroups = []
    }

    func postImage(_ image: MediaAsset) {
        guard let data = image.imageData else { return }
        sendController.sendMessage(withImageData: data)
    }

    func deallocateUnusedInputControllers() {
        if cameraKeyboardViewController != inputController {
            cameraKeyboardViewController = nil
        }
        if audioRecordKeyboardViewController != inputController {
            audioRecordKeyboardViewController = nil
        }
        if ephemeralKeyboardViewController != inputController {
            ephemeralKeyboardViewController = nil
        }
    }

    // MARK: - PingButton

    @objc
    private func pingButtonPressed(_ button: UIButton?) {
        appendKnock()
    }

    private func appendKnock() {
        guard let conversation = conversation as? ZMConversation else { return }

        notificationFeedbackGenerator.prepare()
        ZMUserSession.shared()?.enqueue({
            do {
                try conversation.appendKnock()
                Analytics.shared.tagMediaActionCompleted(.ping, inConversation: conversation)

                AVSMediaManager.sharedInstance().playKnockSound()
                self.notificationFeedbackGenerator.notificationOccurred(.success)
            } catch {
                Logging.messageProcessing.warn("Failed to append knock. Reason: \(error.localizedDescription)")
            }
        })

        pingButton.isEnabled = false
        delay(0.5) {
            self.pingButton.isEnabled = true
        }
    }

    // MARK: - SendButton

    @objc
    func sendButtonPressed(_ sender: Any?) {
        inputBar.textView.autocorrectLastWord()
        sendText()
    }

    // MARK: - Giphy

    @objc
    private func giphyButtonPressed(_ sender: Any?) {
        guard !AppDelegate.isOffline,
                let conversation = conversation as? ZMConversation else { return }

        let giphySearchViewController = GiphySearchViewController(searchTerm: "", conversation: conversation)
        giphySearchViewController.delegate = self
        ZClientViewController.shared?.present(giphySearchViewController.wrapInsideNavigationController(), animated: true)
    }

    // MARK: - Animations
    func bounceCameraIcon() {
        let scaleTransform = CGAffineTransform(scaleX: 1.3, y: 1.3)

        let scaleUp = {
            self.photoButton.transform = scaleTransform
        }

        let scaleDown = {
            self.photoButton.transform = CGAffineTransform.identity
        }

        UIView.animate(withDuration: 0.1, delay: 0, options: .curveEaseIn, animations: scaleUp) { _ in
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.6, options: .curveEaseOut, animations: scaleDown)
        }
    }

    // MARK: - Haptic Feedback
    func playInputHapticFeedback() {
        impactFeedbackGenerator.prepare()
        impactFeedbackGenerator.impactOccurred()
    }

    // MARK: - Input views handling
    @objc
    func onSingleTap(_ recognier: UITapGestureRecognizer?) {
        if recognier?.state == .recognized {
            mode = .textInput
        }
    }

    // MARK: - notification center
    private func setupNotificationCenter() {

        NotificationCenter.default.addObserver(forName: UIResponder.keyboardDidHideNotification,
                                               object: nil,
                                               queue: .main) { [weak self] _ in

            guard let weakSelf = self else { return }

            let inRotation = weakSelf.inRotation
            let isRecording = weakSelf.audioRecordKeyboardViewController?.isRecording ?? false

            if !inRotation && !isRecording {
                weakSelf.mode = .textInput
            }
        }

        NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification,
                                               object: nil,
                                               queue: .main) { [weak self] _ in

            self?.didEnterBackground()
        }

        NotificationCenter.default.addObserver(forName: .featureDidChangeNotification,
                                               object: nil,
                                               queue: .main) { [weak self] _ in

            self?.updateViewsForSelfDeletingMessageChanges()
        }
    }

    // MARK: - Keyboard Shortcuts
    override var canBecomeFirstResponder: Bool {
        return true
    }

}

// MARK: - GiphySearchViewControllerDelegate

extension ConversationInputBarViewController: GiphySearchViewControllerDelegate {
    func giphySearchViewController(_ giphySearchViewController: GiphySearchViewController, didSelectImageData imageData: Data, searchTerm: String) {
        clearInputBar()
        dismiss(animated: true) {
            let messageText: String

            if searchTerm == "" {
                messageText = String(format: "giphy.conversation.random_message".localized, searchTerm)
            } else {
                messageText = String(format: "giphy.conversation.message".localized, searchTerm)
            }

            self.sendController.sendTextMessage(messageText, mentions: [], withImageData: imageData)
        }
    }
}

// MARK: - UIImagePickerControllerDelegate

extension ConversationInputBarViewController: UIImagePickerControllerDelegate {

    /// TODO: check this is still necessary on iOS 13?
    private func statusBarBlinksRedFix() {
        // Workaround http://stackoverflow.com/questions/26651355/
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
        }
    }

    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        statusBarBlinksRedFix()

        let mediaType = info[UIImagePickerController.InfoKey.mediaType] as? String

        if mediaType == kUTTypeMovie as String {
            processVideo(info: info, picker: picker)
        } else if mediaType == kUTTypeImage as String {
            let image: UIImage? = (info[UIImagePickerController.InfoKey.editedImage] as? UIImage) ?? info[UIImagePickerController.InfoKey.originalImage] as? UIImage

            if let image = image,
               let jpegData = image.jpegData(compressionQuality: 0.9) {
                if picker.sourceType == UIImagePickerController.SourceType.camera {
                    if mediaShareRestrictionManager.hasAccessToCameraRoll {
                        UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
                    }
                    // In case of picking from the camera, the iOS controller is showing it's own confirmation screen.
                    parent?.dismiss(animated: true) {
                        self.sendController.sendMessage(withImageData: jpegData, completion: nil)
                    }
                } else {
                    parent?.dismiss(animated: true) {
                        self.showConfirmationForImage(jpegData, isFromCamera: false, uti: mediaType)
                    }
                }

            }
        } else {
            parent?.dismiss(animated: true)
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        statusBarBlinksRedFix()

        parent?.dismiss(animated: true) {

            if self.shouldRefocusKeyboardAfterImagePickerDismiss {
                self.shouldRefocusKeyboardAfterImagePickerDismiss = false
                self.mode = .camera
                self.inputBar.textView.becomeFirstResponder()
            }
        }
    }

    // MARK: - Sketch

    @objc
    func sketchButtonPressed(_ sender: Any?) {
        inputBar.textView.resignFirstResponder()

        let viewController = CanvasViewController()
        viewController.delegate = self
        viewController.navigationItem.setupNavigationBarTitle(title: conversation.displayName.capitalized)

        parent?.present(viewController.wrapInNavigationController(setBackgroundColor: true), animated: true)
    }
}

// MARK: - Informal TextView delegate methods

extension ConversationInputBarViewController: InformalTextViewDelegate {
    func textView(_ textView: UITextView, hasImageToPaste image: MediaAsset) {
        let context = ConfirmAssetViewController.Context(asset: .image(mediaAsset: image),
                                                         onConfirm: {[weak self] editedImage in
                                                            self?.dismiss(animated: false)
                                                            self?.postImage(editedImage ?? image)
            },
                                                         onCancel: { [weak self] in
                                                            self?.dismiss(animated: false)
            }
        )

        let confirmImageViewController = ConfirmAssetViewController(context: context)

        confirmImageViewController.previewTitle = conversation.displayName.localized

        present(confirmImageViewController, animated: false)
    }

    func textView(_ textView: UITextView, firstResponderChanged resigned: Bool) {
        updateAccessoryViews()
        updateNewButtonTitleLabel()
    }
}

// MARK: - ZMConversationObserver

extension ConversationInputBarViewController: ZMConversationObserver {
    func conversationDidChange(_ change: ConversationChangeInfo) {
        if change.participantsChanged ||
            change.connectionStateChanged ||
            change.allowGuestsChanged {
            // Sometime participantsChanged is not observed after allowGuestsChanged
            updateInputBarVisibility()
            updateClassificationBanner()
        }

        if change.destructionTimeoutChanged {
            updateViewsForSelfDeletingMessageChanges()
        }
    }
}

// MARK: - ZMUserObserver

extension ConversationInputBarViewController: ZMUserObserver {
    func userDidChange(_ changeInfo: UserChangeInfo) {
        if changeInfo.availabilityChanged {
            updateAvailabilityPlaceholder()
        }
    }
}

// MARK: - UIGestureRecognizerDelegate

extension ConversationInputBarViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return singleTapGestureRecognizer == gestureRecognizer || singleTapGestureRecognizer == otherGestureRecognizer
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if singleTapGestureRecognizer == gestureRecognizer {
            return true
        }

        return gestureRecognizer.view?.bounds.contains(touch.location(in: gestureRecognizer.view)) ?? false
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return otherGestureRecognizer is UIPanGestureRecognizer
    }

    // MARK: setup views

    private func setupViews() {
        updateEphemeralIndicatorButtonTitle(ephemeralIndicatorButton)

        setupInputBar()

        inputBar.rightAccessoryStackView.addArrangedSubview(sendButton)
        inputBar.leftAccessoryView.addSubview(markdownButton)
        inputBar.rightAccessoryStackView.insertArrangedSubview(ephemeralIndicatorButton, at: 0)
        inputBar.addSubview(typingIndicatorView)

        view.addSubview(securityLevelView)

        createConstraints()
    }

    private func setupInputBar() {
        audioButton.accessibilityIdentifier = "audioButton"
        videoButton.accessibilityIdentifier = "videoButton"
        photoButton.accessibilityIdentifier = "photoButton"
        uploadFileButton.accessibilityIdentifier = "uploadFileButton"
        sketchButton.accessibilityIdentifier = "sketchButton"
        pingButton.accessibilityIdentifier = "pingButton"
        locationButton.accessibilityIdentifier = "locationButton"
        gifButton.accessibilityIdentifier = "gifButton"
        mentionButton.accessibilityIdentifier = "mentionButton"
        markdownButton.accessibilityIdentifier = "markdownButton"

        inputBarButtons.forEach {
            $0.hitAreaPadding = .zero
        }

        inputBar.textView.delegate = self
        inputBar.textView.informalTextViewDelegate = self
        registerForTextFieldSelectionChange()

        view.addSubview(inputBar)

        inputBar.editingView.delegate = self
        setupAccessibility()
    }

    private func setupAccessibility() {
        typealias Conversation = L10n.Accessibility.Conversation

        photoButton.accessibilityLabel = Conversation.CameraButton.description
        mentionButton.accessibilityLabel = Conversation.MentionButton.description
        sketchButton.accessibilityLabel = Conversation.SketchButton.description
        gifButton.accessibilityLabel = Conversation.GifButton.description
        audioButton.accessibilityLabel = Conversation.AudioButton.description
        pingButton.accessibilityLabel = Conversation.PingButton.description
        uploadFileButton.accessibilityLabel = Conversation.UploadFileButton.description
        locationButton.accessibilityLabel = Conversation.LocationButton.description
        videoButton.accessibilityLabel = Conversation.VideoButton.description
        hourglassButton.accessibilityLabel = Conversation.TimerButton.description
        sendButton.accessibilityLabel = Conversation.SendButton.description
    }

    private func createConstraints() {
        [securityLevelView, inputBar, markdownButton, typingIndicatorView].prepareForLayout()

        let bottomConstraint = inputBar.bottomAnchor.constraint(equalTo: inputBar.superview!.bottomAnchor)
        bottomConstraint.priority = .defaultLow

        let securityBannerHeight: CGFloat = securityLevelView.isHidden ? 0 : 24
        let widthOfSendButton: CGFloat = 42
        let heightOfSendButton: CGFloat = 32

        NSLayoutConstraint.activate([
            securityLevelView.topAnchor.constraint(equalTo: view.topAnchor),
            securityLevelView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            securityLevelView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            securityLevelView.heightAnchor.constraint(equalToConstant: securityBannerHeight),

            inputBar.topAnchor.constraint(equalTo: securityLevelView.bottomAnchor),
            inputBar.leadingAnchor.constraint(equalTo: inputBar.superview!.leadingAnchor),
            inputBar.trailingAnchor.constraint(equalTo: inputBar.superview!.trailingAnchor),
            bottomConstraint,

            sendButton.widthAnchor.constraint(equalToConstant: InputBar.rightIconSize),
            sendButton.heightAnchor.constraint(equalToConstant: InputBar.rightIconSize),

            ephemeralIndicatorButton.widthAnchor.constraint(equalToConstant: InputBar.rightIconSize),
            ephemeralIndicatorButton.heightAnchor.constraint(equalToConstant: InputBar.rightIconSize),

            markdownButton.centerXAnchor.constraint(equalTo: markdownButton.superview!.centerXAnchor),
            markdownButton.bottomAnchor.constraint(equalTo: markdownButton.superview!.bottomAnchor, constant: -14),

            markdownButton.widthAnchor.constraint(equalToConstant: widthOfSendButton),
            markdownButton.heightAnchor.constraint(equalToConstant: heightOfSendButton),

            typingIndicatorView.centerYAnchor.constraint(equalTo: inputBar.topAnchor),
            typingIndicatorView.centerXAnchor.constraint(equalTo: typingIndicatorView.superview!.centerXAnchor),
            typingIndicatorView.leftAnchor.constraint(greaterThanOrEqualTo: typingIndicatorView.superview!.leftAnchor, constant: 48),
            typingIndicatorView.rightAnchor.constraint(lessThanOrEqualTo: typingIndicatorView.superview!.rightAnchor, constant: 48)
        ])
    }
}
