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

import UIKit
import Social
import WireShareEngine
import MobileCoreServices
import WireDataModel
import WireCommonComponents
import WireLinkPreview
import LocalAuthentication

typealias Completion = () -> Void
private let zmLog = ZMSLog(tag: "UI")

/// The delay after which a progess view controller will be displayed if all messages are not yet sent.
private let progressDisplayDelay: TimeInterval = 0.5

private enum LocalAuthenticationStatus {
    case disabled
    case denied
    case granted
}

final class ShareExtensionViewController: SLComposeServiceViewController {

    // MARK: - Elements

    lazy var accountItem: SLComposeSheetConfigurationItem = { [weak self] in
        let item = SLComposeSheetConfigurationItem()!
        let accountName = self?.currentAccount?.shareExtensionDisplayName

        item.title = "share_extension.conversation_selection.account".localized
        item.value = accountName ?? "share_extension.conversation_selection.empty.value".localized
        item.tapHandler = { [weak self] in
            self?.presentChooseAccount()
        }
        return item
    }()

    lazy var conversationItem: SLComposeSheetConfigurationItem = {
        let item = SLComposeSheetConfigurationItem()!

        item.title = "share_extension.conversation_selection.title".localized
        item.value = "share_extension.conversation_selection.empty.value".localized
        item.tapHandler = { [weak self] in
            self?.presentChooseConversation()
        }
        return item
    }()

    lazy var preview: PreviewImageView? = {
        let imageView = PreviewImageView(frame: .zero)
        imageView.clipsToBounds = true
        imageView.shouldGroupAccessibilityChildren = true
        imageView.isAccessibilityElement = false
        return imageView
    }()

    fileprivate var postContent: PostContent?
    fileprivate var sharingSession: SharingSession?

    /// stores extensionContext?.attachments
    fileprivate var attachments: [AttachmentType: [NSItemProvider]] = [:]

    fileprivate var currentAccount: Account? {
        didSet {
            localAuthenticationStatus = .denied
        }
    }

    fileprivate var localAuthenticationStatus: LocalAuthenticationStatus = .denied
    private var observer: SendableBatchObserver?
    private weak var progressViewController: SendingProgressViewController?

    var dispatchQueue: DispatchQueue = DispatchQueue.main
    let stateAccessoryView = ConversationStateAccessoryView()

    lazy var unlockViewController = UnlockViewController()

    // MARK: - Host App State

    private var accountManager: AccountManager? {
        guard let applicationGroupIdentifier = Bundle.main.applicationGroupIdentifier else { return nil }
        let sharedContainerURL = FileManager.sharedContainerDirectory(for: applicationGroupIdentifier)
        return AccountManager(sharedDirectory: sharedContainerURL)
    }

    // MARK: - Configuration

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setup()
    }

    private func setup() {
        setupObserver()
        if let dd = DatadogWrapper.shared {
            print("SHARING: dd start monitoring")
            dd.startMonitoring()
        }
    }

    private func setupObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(extensionHostDidEnterBackground), name: .NSExtensionHostDidEnterBackground, object: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        currentAccount = accountManager?.selectedAccount
        ExtensionBackupExcluder.exclude()
        CrashReporter.setupAppCenterIfNeeded()
        updateAccount(currentAccount)

        if let sortedAttachments = extensionContext?.attachments.sorted {
            attachments = sortedAttachments
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.postContent = PostContent(attachments: extensionContext?.attachments ?? [])
        self.setupNavigationBar()
        self.appendTextToEditor()
        appendFileTextToEditor()
        self.updatePreview()
        self.placeholder = "share_extension.input.placeholder".localized
    }

    private func setupNavigationBar() {
        let iconSize = CGSize(width: 32, height: 26.3)
        guard let item = navigationController?.navigationBar.items?.first else { return }
        item.rightBarButtonItem?.action = #selector(appendPostTapped)
        item.rightBarButtonItem?.title = "share_extension.send_button.title".localized
        item.titleView = UIImageView(image: WireStyleKit.imageOfLogo(color: UIColor.Wire.primaryLabel).downscaling(to: iconSize))
    }

    private var authenticatedAccounts: [Account] {
        guard let accountManager = accountManager else { return [] }
        return accountManager.accounts.filter { BackendEnvironment.shared.isAuthenticated($0) }
    }

    private func recreateSharingSession(account: Account?) throws {
        guard let applicationGroupIdentifier = Bundle.main.applicationGroupIdentifier,
            let hostBundleIdentifier = Bundle.main.hostBundleIdentifier,
            let accountIdentifier = account?.userIdentifier
            else { return }

        let legacyConfig = AppLockController.LegacyConfig.fromBundle()

        sharingSession = try SharingSession(
            applicationGroupIdentifier: applicationGroupIdentifier,
            accountIdentifier: accountIdentifier,
            hostBundleIdentifier: hostBundleIdentifier,
            environment: BackendEnvironment.shared,
            appLockConfig: legacyConfig
        )
    }

    override func configurationItems() -> [Any]! {
        if accountManager?.accounts.count > 1 {
            return [accountItem, conversationItem]
        } else {
            return [conversationItem]
        }
    }

    // MARK: - Events

    @objc private func extensionHostDidEnterBackground() {
        postContent?.cancel { [weak self] in
            self?.cancel()
        }
    }

    override func presentationAnimationDidFinish() {
        if authenticatedAccounts.count == 0 {
            return presentNotSignedInMessage()
        }
    }

    // MARK: - Editing

    override func isContentValid() -> Bool {
        // Do validation of contentText and/or NSExtensionContext attachments here
        let textLength = self.contentText.trimmingCharacters(in: .whitespaces).count
        let remaining = SharedConstants.maximumMessageLength - textLength
        let remainingCharactersThreshold = 30

        if remaining <= remainingCharactersThreshold {
            self.charactersRemaining = remaining as NSNumber
        } else {
            self.charactersRemaining = nil
        }

        let conditions = sharingSession != nil && self.postContent?.target != nil
        return self.charactersRemaining == nil ? conditions : conditions && self.charactersRemaining.intValue >= 0
    }

    /// If there is a URL attachment, copy the text of the URL attachment into the text field
    private func appendTextToEditor() {
        guard let urlItems = attachments[.url] else {
            return
        }

        urlItems.first?.fetchURL { url in
            DispatchQueue.main.async {
                guard let url = url, !url.isFileURL else { return }
                let separator = self.textView.text.isEmpty ? "" : "\n"
                self.textView.text += separator + url.absoluteString
                self.textView.delegate?.textViewDidChange?(self.textView)
            }
        }
    }

    /// If there is a File URL attachment, copy the filename of the URL attachment into the text field
    private func appendFileTextToEditor() {
        guard let urlItems = attachments[.fileUrl] else {
            return
        }

        urlItems.first?.loadItem(forTypeIdentifier: kUTTypeFileURL as String, options: nil, completionHandler: { (url, error) in
            error?.log(message: "Unable to fetch URL for type URL")
            guard let url = url as? URL, url.isFileURL else { return }

            let filename = url.lastPathComponent
            let separator = self.textView.text.isEmpty ? "" : "\n"

            DispatchQueue.main.async {
                self.textView.text += separator + filename
                self.textView.delegate?.textViewDidChange?(self.textView)
            }

        })
    }

    /// Invoked when the user wants to post.
    @objc
    private func appendPostTapped() {
        let logger = WireLogger(tag: "share extension")
        logger.info("SHARING: Append Post Tapped")
        guard let sharingSession = sharingSession else {
            return
            logger.info("SHARING: Sharing session aborted")
        }

        navigationController?.navigationBar.items?.first?.rightBarButtonItem?.isEnabled = false

        postContent?.send(text: contentText, sharingSession: sharingSession) { [weak self] progress in
            guard let `self` = self, let postContent = self.postContent else { return }

            switch progress {
            case .preparing:
                logger.info(
                    SharingLog(status: .preparing)
                )
                DispatchQueue.main.asyncAfter(deadline: .now() + progressDisplayDelay) {
                    guard !postContent.sentAllSendables && nil == self.progressViewController else { return }
                    self.presentSendingProgress(mode: .preparing)
                }

                print("SHARING: Preparing state")

            case .startingSending:
                logger.info(
                    SharingLog(status: .started)
                )
                DispatchQueue.main.asyncAfter(deadline: .now() + progressDisplayDelay) {
                    guard postContent.sentAllSendables && nil == self.progressViewController else { return }
                    self.presentSendingProgress(mode: .sending)
                }

                print("SHARING: Starting sending state")

            case .sending(let progress):
                logger.info(
                    SharingLog(status: .sending, progress: .progress)
                )
                self.progressViewController?.progress = progress

                print("SHARING: Sending state")
            case .done:
                logger.info(
                    SharingLog(status: .done)
                )
                UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn, animations: {
                    self.view.alpha = 0
                    self.navigationController?.view.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
                }, completion: { _ in
                    self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
                })

                print("SHARING: done state")

            case .conversationDidDegrade((let users, let strategyChoice)):
                logger.info(
                    SharingLog(status: .conversationDegraded)
                )
                if let conversation = postContent.target {
                    self.conversationDidDegrade(
                        change: ConversationDegradationInfo(conversation: conversation, users: users),
                        callback: strategyChoice)
                }
            case .timedOut:
                logger.info(
                    SharingLog(status: .timedOut)
                )
                self.popConfigurationViewController()

                let alert = UIAlertController.alertWithOKButton(title: "share_extension.timeout.title".localized, message: "share_extension.timeout.message".localized)

                self.present(alert, animated: true)

                print("SHARING: timeout state")

            case .error(let error):
                if let errorDescription = (error as? UnsentSendableError )?.errorDescription {
                    let alert = UIAlertController.alertWithOKButton(title: nil, message: errorDescription)
                    self.present(alert, animated: true) {
                        self.popConfigurationViewController()
                    }
                    logger.info(
                        SharingLog(status: .error, errorDescription: errorDescription)
                    )

                    print("SHARING: error state \(errorDescription)")
                }
            case .fileSharingRestriction:
                logger.info(
                    SharingLog(status: .fileSharingRestricted)
                )
                let alert = UIAlertController.alertWithOKButton(title: "feature.flag.file_sharing.alert.title".localized,
                                                                message: "feature.flag.file_sharing.alert.message" .localized)
                self.present(alert, animated: true)
            }
        }
    }

    // MARK: - Preview

    /// Display a preview image.
    override func loadPreviewView() -> UIView! {
        return preview
    }

    func updatePreview() {
        fetchMainAttachmentPreview { previewItem, displayMode in
            DispatchQueue.main.async {
                guard let previewItem = previewItem else {
                    self.preview?.image = nil
                    self.preview?.isHidden = true
                    return
                }

                switch previewItem {
                case .image(let image):
                    self.preview?.image = image
                    self.preview?.displayMode = displayMode
                case .placeholder(let iconType):
                    self.preview?.setIcon(iconType, size: .medium, color: UIColor.Wire.secondaryLabel)

                case .remoteURL(let url):
                    self.preview?.setIcon(.browser, size: .medium, color: UIColor.Wire.secondaryLabel)
                    self.fetchWebsitePreview(for: url)
                }

                self.preview?.displayMode = displayMode
                self.preview?.isHidden = false
            }
        }
    }

    /// Fetches the preview image for the given website.
    private func fetchWebsitePreview(for url: URL) {
        sharingSession?.downloadLinkPreviews(inText: url.absoluteString, excluding: []) { previews in
            let previewImage: UIImage?

            // Size the image to fill the image view
            if let imageData = previews.first?.imageData.first,
               let image = UIImage(data: imageData),
               let requiredSize = self.preview?.frame.size.shortestLength {
                previewImage = image.downsized(shorterSizeLength: requiredSize)
            } else {
                previewImage = nil
            }

            DispatchQueue.main.async {
                self.preview?.displayMode = .link
                self.preview?.image = previewImage
            }
        }
    }

    // MARK: - Transitions

    private func presentSendingProgress(mode: SendingProgressViewController.ProgressMode) {
        let progressSendingViewController = SendingProgressViewController()
        progressViewController?.mode = mode

        progressSendingViewController.cancelHandler = { [weak self] in
            self?.postContent?.cancel {
                self?.cancel()
            }
        }

        progressViewController = progressSendingViewController
        pushConfigurationViewController(progressSendingViewController)
    }

    private func presentNotSignedInMessage() {
        let notSignedInViewController = NotSignedInViewController()

        notSignedInViewController.closeHandler = { [weak self] in
            self?.cancel()
        }

        pushConfigurationViewController(notSignedInViewController)
    }

    func updateState(conversation: WireShareEngine.Conversation?) {
        conversationItem.value = conversation?.name ?? "share_extension.conversation_selection.empty.value".localized
        postContent?.target = conversation
    }

    func updateAccount(_ account: Account?) {

        var account = account
        let authenticated = authenticatedAccounts

        // If the current account is not authenticated (e.g. device removed from another client)
        // and there are other accounts authenticated, it switches to the first available.

        let accountAuthenticated = account.flatMap(BackendEnvironment.shared.isAuthenticated) ?? false

        if let firstLogged = authenticated.first, account == currentAccount, accountAuthenticated == false {
            account = firstLogged
        }

        do {
            try recreateSharingSession(account: account)
        } catch let error as SharingSession.InitializationError {
            guard error == .loggedOut else { return }

            let alert = UIAlertController.alertWithOKButton(title: "share_extension.logged_out.title".localized, message: "share_extension.logged_out.message".localized)

            self.present(alert, animated: true)
            return
        } catch { // any other error
            return
        }

        currentAccount = account
        accountItem.value = account?.shareExtensionDisplayName ?? ""
        conversationItem.value = "share_extension.conversation_selection.empty.value".localized

        guard account != currentAccount else { return }
        postContent?.target = nil
    }

    private func presentChooseAccount() {
        showChooseAccount()
    }

    private func presentChooseConversation() {
        requireLocalAuthenticationIfNeeded { [weak self] in
            guard let `self` = self,
                self.localAuthenticationStatus == .granted else { return }

            self.showChooseConversation()
        }
    }

    func showChooseConversation() {

        guard let sharingSession = sharingSession else { return }

        let allConversations = sharingSession.writeableNonArchivedConversations + sharingSession.writebleArchivedConversations
        let conversationSelectionViewController = ConversationSelectionViewController(conversations: allConversations)

        conversationSelectionViewController.selectionHandler = { [weak self] conversation in
            self?.updateState(conversation: conversation)
            self?.popConfigurationViewController()
            self?.validateContent()
        }

        pushConfigurationViewController(conversationSelectionViewController)
    }

    func showChooseAccount() {

        guard let accountManager = accountManager else { return }
        let accountSelectionViewController = AccountSelectionViewController(accounts: accountManager.accounts,
                                                                            current: currentAccount)

        accountSelectionViewController.selectionHandler = { [weak self] account in
            self?.updateAccount(account)
            self?.popConfigurationViewController()
            self?.validateContent()
        }

        pushConfigurationViewController(accountSelectionViewController)
    }

    private func conversationDidDegrade(change: ConversationDegradationInfo, callback: @escaping DegradationStrategyChoice) {
        let title = titleForMissingClients(causedBy: change)
        let alert = UIAlertController(title: title, message: "meta.degraded.dialog_message".localized, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "meta.degraded.send_anyway_button".localized, style: .destructive, handler: { _ in
            callback(.sendAnyway)
        }))
        alert.addAction(UIAlertAction(title: "meta.degraded.cancel_sending_button".localized, style: .cancel, handler: { _ in
            callback(.cancelSending)
        }))
        self.present(alert, animated: true)
    }

    private func titleForMissingClients(causedBy change: ConversationDegradationInfo) -> String {
        if change.conversation.legalHoldStatus == .pendingApproval {
            return "meta.legalhold.send_alert_title".localized
        }

        let users = change.users
        let template = users.count > 1 ? "meta.degraded.degradation_reason_message.plural" : "meta.degraded.degradation_reason_message.singular"

        let allUsers = (users.compactMap(\.name) as NSArray).componentsJoined(by: ", ") as NSString
        return String.localizedStringWithFormat(template.localized, allUsers)
    }

}

// MARK: - Authentication

extension ShareExtensionViewController {

    /// @param completion; called when authentication evaluation is completed.
    private func requireLocalAuthenticationIfNeeded(with completion: @escaping Completion) {
        guard
            let sharingSession = sharingSession,
            sharingSession.appLockController.isActive || sharingSession.encryptMessagesAtRest
        else {
            localAuthenticationStatus = .granted
            completion()
            return
        }

        guard localAuthenticationStatus == .denied || sharingSession.isDatabaseLocked else {
            completion()
            return
        }

        let appLock = sharingSession.appLockController
        let description = "share_extension.privacy_security.lock_app.description".localized
        let passcodePreference: AppLockPasscodePreference

        if sharingSession.encryptMessagesAtRest {
            passcodePreference = .deviceOnly
        } else if appLock.requireCustomPasscode {
            passcodePreference = .customOnly
        } else {
            passcodePreference = .deviceThenCustom
        }

        appLock.evaluateAuthentication(passcodePreference: passcodePreference, description: description) { [weak self] result, context in
            guard let `self` = self else { return }

            DispatchQueue.main.async {
                if case .granted = result, let context = context as? LAContext {
                  try? self.sharingSession?.unlockDatabase(with: context)
                }

                self.authenticationEvaluated(with: result, completion: completion)
            }
        }
    }

    private func authenticationEvaluated(with result: AppLockAuthenticationResult, completion: @escaping Completion) {
        switch result {
        case .granted:
            localAuthenticationStatus = .granted
            completion()
        case .needCustomPasscode:
            let isCustomPasscodeSet = sharingSession?.appLockController.isCustomPasscodeSet ?? false
            if !isCustomPasscodeSet {
                let alert = UIAlertController(title: "", message: "share_extension.unlock.alert.message".localized, alertAction: .ok(style: .cancel))
                self.present(alert, animated: true, completion: nil)

                localAuthenticationStatus = .denied
                completion()
            } else {
                requestCustomPasscode { [weak self] status in
                    guard let `self` = self else { return }

                    self.localAuthenticationStatus = status
                    completion()
                }
            }
        default:
            localAuthenticationStatus = .denied
            completion()
        }
    }

    private func requestCustomPasscode(with callback: @escaping (_ status: LocalAuthenticationStatus) -> Void) {
        presentUnlockScreen { [weak self] customPasscode in
            guard let `self` = self else { return }

            guard
                let passcode = customPasscode,
                !passcode.isEmpty,
                let appLock = self.sharingSession?.appLockController,
                appLock.evaluateAuthentication(customPasscode: passcode) == .granted
            else {
                self.unlockViewController.showWrongPasscodeMessage()
                callback(.denied)
                return
            }

            self.popConfigurationViewController()
            callback(.granted)
        }
    }

    private func presentUnlockScreen(with callback: @escaping (_ password: String?) -> Void) {
        pushConfigurationViewController(unlockViewController)

        unlockViewController.callback = callback
    }
}
