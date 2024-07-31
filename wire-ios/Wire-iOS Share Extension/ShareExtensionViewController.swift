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

import LocalAuthentication
import MobileCoreServices
import Social
import UIKit
import UniformTypeIdentifiers
import WireCommonComponents
import WireCoreCrypto
import WireDataModel
import WireDesign
import WireLinkPreview
import WireShareEngine

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

    typealias ShareExtensionConversationLocale = L10n.ShareExtension.ConversationSelection

    let maximumMessageLength = 8000

    lazy var accountItem: SLComposeSheetConfigurationItem = { [weak self] in
        let item = SLComposeSheetConfigurationItem()!
        let accountName = self?.currentAccount?.shareExtensionDisplayName

        item.title = ShareExtensionConversationLocale.account
        item.value = accountName ?? ShareExtensionConversationLocale.Empty.value
        item.tapHandler = { [weak self] in
            self?.presentChooseAccount()
        }
        return item
    }()

    lazy var conversationItem: SLComposeSheetConfigurationItem = {
        let item = SLComposeSheetConfigurationItem()!

        item.title = ShareExtensionConversationLocale.title
        item.value = ShareExtensionConversationLocale.Empty.value
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

    private var postContent: PostContent?
    private var sharingSession: SharingSession?

    /// stores extensionContext?.attachments
    private var attachments: [AttachmentType: [NSItemProvider]] = [:]

    private var currentAccount: Account? {
        didSet {
            localAuthenticationStatus = .denied
        }
    }

    private var localAuthenticationStatus: LocalAuthenticationStatus = .denied
    private var observer: SendableBatchObserver?
    private let networkStatusObservable: any NetworkStatusObservable = NetworkStatus.shared
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
        setUpObserver()
        setUpDatadog()
    }

    private func setUpObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(extensionHostDidEnterBackground),
            name: .NSExtensionHostDidEnterBackground,
            object: nil
        )
    }

    private func setUpDatadog() {
        WireAnalytics.Datadog.enable()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        WireLogger.shareExtension.info("share extension loaded")
        currentAccount = accountManager?.selectedAccount
        ExtensionBackupExcluder.exclude()
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

        self.placeholder = L10n.ShareExtension.Input.placeholder
    }

    private func setupNavigationBar() {
        let iconSize = CGSize(width: 32, height: 26.3)
        guard let item = navigationController?.navigationBar.items?.first else { return }
        item.rightBarButtonItem?.action = #selector(appendPostTapped)
        item.rightBarButtonItem?.title = L10n.ShareExtension.SendButton.title
        item.titleView = UIImageView(image: WireStyleKit.imageOfLogo(color: UIColor.Wire.primaryLabel).downscaling(to: iconSize))
    }

    private var authenticatedAccounts: [Account] {
        guard let accountManager else { return [] }
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
            appLockConfig: legacyConfig,
            sharedUserDefaults: .applicationGroup,
            minTLSVersion: SecurityFlags.minTLSVersion.stringValue
        )
    }

    override func configurationItems() -> [Any]! {
        if let count = accountManager?.accounts.count, count > 1 {
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
        let remaining = maximumMessageLength - textLength
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
                guard let url, !url.isFileURL else { return }
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

        urlItems.first?.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil, completionHandler: { url, error in
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
        WireLogger.shareExtension.info("user wants to send content with \(postContent?.attachments.count ?? 0) attachments")

        guard let sharingSession else {
            WireLogger.shareExtension.error("failed to send attachments: no sharing session")
            return
        }

        navigationController?.navigationBar.items?.first?.rightBarButtonItem?.isEnabled = false

        postContent?.send(text: contentText, sharingSession: sharingSession) { [weak self] progress in
            guard let self, let postContent = self.postContent else { return }

            switch progress {
            case .preparing:
                WireLogger.shareExtension.info("progress event: preparing")
                DispatchQueue.main.asyncAfter(deadline: .now() + progressDisplayDelay) {
                    guard !postContent.sentAllSendables && self.progressViewController == nil else { return }
                    self.presentSendingProgress(mode: .preparing)
                }

            case .startingSending:
                WireLogger.shareExtension.info("progress event: start sending")
                DispatchQueue.main.asyncAfter(deadline: .now() + progressDisplayDelay) {
                    guard postContent.sentAllSendables && self.progressViewController == nil else { return }
                    self.presentSendingProgress(mode: .sending)
                }

            case .sending(let progress):
                WireLogger.shareExtension.info("progress event: sending with progress: (\(progress))")
                self.progressViewController?.progress = progress

            case .done:
                WireLogger.shareExtension.info("progress event: done")
                UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn, animations: {
                    self.view.alpha = 0
                    self.navigationController?.view.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
                }, completion: { _ in
                    self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
                })

            case .conversationDidDegrade((let users, let strategyChoice)):
                WireLogger.shareExtension.warn("progress event: converation did degrade")
                if let conversation = postContent.target {
                    self.conversationDidDegrade(
                        change: ConversationDegradationInfo(conversation: conversation, users: users),
                        callback: strategyChoice)
                }
            case .timedOut:
                WireLogger.shareExtension.error("progress event: timed out")
                self.popConfigurationViewController()

                let alert = UIAlertController(
                    title: L10n.ShareExtension.Timeout.title,
                    message: L10n.ShareExtension.Timeout.message,
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(
                    title: L10n.General.ok,
                    style: .cancel
                ))

                self.present(alert, animated: true)

            case .error(let error):
                WireLogger.shareExtension.error("progress event: error: \(error.localizedDescription)")

                if let errorDescription = (error as? UnsentSendableError)?.errorDescription {
                    let alert = UIAlertController(
                        title: nil,
                        message: errorDescription,
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(
                        title: L10n.General.ok,
                        style: .cancel,
                        handler: { _ in
                            self.extensionContext?.completeRequest(returningItems: [])
                        }
                    ))

                    self.present(alert, animated: true) {
                        self.popConfigurationViewController()
                    }
                }
            case .fileSharingRestriction:
                WireLogger.shareExtension.warn("progress event: file sharing restricted")

                let alert = UIAlertController(
                    title: L10n.ShareExtension.Feature.Flag.FileSharing.Alert.title,
                    message: L10n.ShareExtension.Feature.Flag.FileSharing.Alert.message,
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(
                    title: L10n.General.ok,
                    style: .cancel
                ))

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
                guard let previewItem else {
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
        let progressSendingViewController = SendingProgressViewController(networkStatusObservable: networkStatusObservable)
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
        conversationItem.value = conversation?.name ?? L10n.ShareExtension.ConversationSelection.Empty.value
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

            let alert = UIAlertController(
                title: L10n.ShareExtension.LoggedOut.title,
                message: L10n.ShareExtension.LoggedOut.message,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(
                title: L10n.General.ok,
                style: .cancel
            ))

            self.present(alert, animated: true)
            return
        } catch { // any other error
            return
        }

        currentAccount = account
        accountItem.value = account?.shareExtensionDisplayName ?? ""
        conversationItem.value = L10n.ShareExtension.ConversationSelection.Empty.value

        guard account != currentAccount else { return }
        postContent?.target = nil
    }

    private func presentChooseAccount() {
        showChooseAccount()
    }

    private func presentChooseConversation() {
        requireLocalAuthenticationIfNeeded { [weak self] in
            guard let self,
                  self.localAuthenticationStatus == .granted else { return }

            self.showChooseConversation()
        }
    }

    func showChooseConversation() {

        guard let sharingSession else { return }

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

        guard let accountManager else { return }
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

        typealias MetaDegradedLocale = L10n.ShareExtension.Meta.Degraded

        let title = titleForMissingClients(causedBy: change)
        let alert = createDegradationAlert(title: title, message: MetaDegradedLocale.dialogMessage, callback: callback)

        self.present(alert, animated: true)
    }

    private func createDegradationAlert(title: String, message: String, callback: @escaping DegradationStrategyChoice) -> UIAlertController {

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: L10n.ShareExtension.Meta.Degraded.sendAnywayButton, style: .destructive, handler: { _ in
            self.handleSendAnyway(callback)
        }))
        alert.addAction(UIAlertAction(title: L10n.ShareExtension.Meta.Degraded.cancelSendingButton, style: .cancel, handler: { _ in
            self.handleCancelSending(callback)
        }))

        return alert
    }

    private func handleSendAnyway(_ callback: DegradationStrategyChoice) {
        callback(.sendAnyway)
    }

    private func handleCancelSending(_ callback: DegradationStrategyChoice) {
        callback(.cancelSending)
    }

    private func titleForMissingClients(causedBy change: ConversationDegradationInfo) -> String {
        if change.conversation.legalHoldStatus == .pendingApproval {
            return L10n.ShareExtension.Meta.Legalhold.sendAlertTitle
        }

        let usersString = formattedUserNames(from: change.users)
        return degradationMessageForUsers(usersString, count: change.users.count)
    }

    private func formattedUserNames(from users: Set<ZMUser>) -> String {
        let names = users.compactMap { $0.name }.joined(separator: ", ")
        return names
    }

    private func degradationMessageForUsers(_ users: String, count: Int) -> String {
        typealias DegradationReasonMessageLocale = L10n.ShareExtension.Meta.Degraded.DegradationReasonMessage
        let messageKey = count > 1 ? DegradationReasonMessageLocale.plural(users) : DegradationReasonMessageLocale.singular(users)
        return messageKey
    }

}

// MARK: - Authentication

extension ShareExtensionViewController {

    /// @param completion; called when authentication evaluation is completed.
    private func requireLocalAuthenticationIfNeeded(with completion: @escaping Completion) {
        guard
            let sharingSession,
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

        let description = L10n.ShareExtension.PrivacySecurity.LockApp.description
        let passcodePreference: AppLockPasscodePreference

        if sharingSession.encryptMessagesAtRest {
            passcodePreference = .deviceOnly
        } else if appLock.requireCustomPasscode {
            passcodePreference = .customOnly
        } else {
            passcodePreference = .deviceThenCustom
        }

        appLock.evaluateAuthentication(
            passcodePreference: passcodePreference,
            description: description
        ) { [weak self] result in
            guard let self else { return }

            DispatchQueue.main.async {
                if case .granted = result {
                    try? self.sharingSession?.unlockDatabase()
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
                let alert = UIAlertController(
                    title: "",
                    message: L10n.ShareExtension.Unlock.Alert.message,
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(
                    title: L10n.General.ok,
                    style: .cancel
                ))

                self.present(alert, animated: true, completion: nil)

                localAuthenticationStatus = .denied
                completion()
            } else {
                requestCustomPasscode { [weak self] status in
                    guard let self else { return }

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
            guard let self else { return }

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
