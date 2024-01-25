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
import UIKit
import WireSyncEngine
import WireCommonComponents

final class ProfileClientViewController: UIViewController, SpinnerCapable {

    // MARK: Properties

    typealias ProfileDevicesDetail = L10n.Localizable.Profile.Devices.Detail

    private var viewModel: ProfileClientViewModel
    private let contentView = UIView()
    private let backButton = IconButton(style: .circular)
    private let showMyDeviceButton = ButtonWithLargerHitArea()
    private let descriptionTextView = UITextView()
    private let separatorLineView = UIView()
    private let typeLabel = UILabel()
    private let IDLabel = UILabel()
    let spinner = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.medium)
    private let fullIDLabel = CopyableLabel()
    private let verifiedToggle = Switch(style: .default)
    private let verifiedToggleLabel = UILabel()
    private let resetButton = ButtonWithLargerHitArea()

    var dismissSpinner: SpinnerCompletion?

    private var userClientToken: NSObjectProtocol!
    var fromConversation: Bool = false

    /// Used for debugging purposes, disabled in public builds
    private var debugMenuButton: ButtonWithLargerHitArea?

    var showBackButton: Bool = true {
        didSet {
            backButton.isHidden = !showBackButton
        }
    }

    private let fingerprintSmallFont = FontSpec(.small, .light).font!
    private let fingerprintSmallBoldFont = FontSpec(.small, .semibold).font!
    private let fingerprintFont = FontSpec(.normal, .none).font!
    private let fingerprintBoldFont = FontSpec(.normal, .semibold).font!

    private let defaultTextColor = SemanticColors.Label.textDefault
    private let defaultBackgroundColor = SemanticColors.View.backgroundDefault

    // MARK: Initilization

    convenience init(
        client: UserClient,
        fromConversation: Bool,
        userSession: UserSession
    ) {
        self.init(client: client, userSession: userSession)
        self.fromConversation = fromConversation
    }

   required init(client: UserClient, userSession: UserSession) {
       self.viewModel = ProfileClientViewModel(userClient: client, getUserClientFingerprint: userSession.getUserClientFingerprint)

        super.init(nibName: nil, bundle: nil)

        userClientToken = UserClientChangeInfo.add(observer: self, for: client)
        self.viewModel.fingerprintDataClosure = { [weak self] fingerprintData in
            self?.updateFingerprintLabel(with: fingerprintData)
        }

        modalPresentationStyle = .overCurrentContext
        title = L10n.Localizable.Registration.Devices.title

        setupViews()
    }

    @available(*, unavailable)
    required override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        fatalError("init(nibNameOrNil:nibBundleOrNil:) has not been implemented")
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Override methods

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return [.portrait]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.loadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        title = ""
    }

    // MARK: Setup UI

    private func setupViews() {
        view.backgroundColor = defaultBackgroundColor

        setupContentView()
        setupBackButton()
        setupShowMyDeviceButton()
        setupDescriptionTextView()
        setupSeparatorLineView()
        setupTypeLabel()
        setupIDLabel()
        setupFullIDLabel()
        setupSpinner()
        setupVerifiedToggle()
        setupVerifiedToggleLabel()
        setupResetButton()
        setupDebugMenuButton()
        createConstraints()
        updateFingerprintLabel(with: nil)
        setupAccessibility()
    }

    private func setupContentView() {
        view.addSubview(contentView)
    }

    private func setupBackButton() {
        backButton.setIcon(.backArrow, size: .tiny, for: [])
        backButton.accessibilityIdentifier = "back"
        backButton.addTarget(self, action: #selector(ProfileClientViewController.onBackTapped(_:)), for: .touchUpInside)
        backButton.isHidden = !showBackButton
        view.addSubview(backButton)
    }

    private func setupShowMyDeviceButton() {
        showMyDeviceButton.accessibilityIdentifier = "show my device"
        showMyDeviceButton.setTitle(ProfileDevicesDetail.ShowMyDevice.title.capitalized, for: [])
        showMyDeviceButton.addTarget(self, action: #selector(ProfileClientViewController.onShowMyDeviceTapped(_:)), for: .touchUpInside)
        showMyDeviceButton.setTitleColor(UIColor.accent(), for: .normal)
        showMyDeviceButton.titleLabel?.font = FontSpec.headerRegularFont.font!
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: showMyDeviceButton)
    }

    private func setupDescriptionTextView() {
        descriptionTextView.isScrollEnabled = false
        descriptionTextView.isEditable = false
        descriptionTextView.delegate = self
        descriptionTextView.textColor = defaultTextColor
        descriptionTextView.backgroundColor = defaultBackgroundColor
        descriptionTextView.linkTextAttributes = [.foregroundColor: UIColor.accent()]

        let descriptionTextFont = FontSpec(.normal, .light).font!

        if let user = viewModel.userClient.user {
            descriptionTextView.attributedText = (L10n.Localizable.Profile.Devices.Detail.verifyMessage(user.name ?? "") &&
                                                  descriptionTextFont &&
                                                  defaultTextColor) +
            "\n" +
            (ProfileDevicesDetail.VerifyMessage.link &&
             [.font: descriptionTextFont, .link: URL.wr_fingerprintHowToVerify])
        }
        contentView.addSubview(descriptionTextView)
    }

    private func setupSeparatorLineView() {
        separatorLineView.backgroundColor = SemanticColors.View.backgroundSeparatorCell
        contentView.addSubview(separatorLineView)
    }

    private func setupTypeLabel() {
        typeLabel.text = viewModel.userClient.deviceClass?.localizedDescription.localizedUppercase
        typeLabel.numberOfLines = 1
        typeLabel.font = FontSpec(.small, .semibold).font!
        typeLabel.textColor = defaultTextColor
        contentView.addSubview(typeLabel)
    }

    private func setupIDLabel() {
        IDLabel.numberOfLines = 1
        IDLabel.textColor = defaultTextColor
        contentView.addSubview(IDLabel)
        updateIDLabel()
    }

    private func setupFullIDLabel() {
        fullIDLabel.numberOfLines = 0
        fullIDLabel.textColor = defaultTextColor
        contentView.addSubview(fullIDLabel)
    }

    private func setupSpinner() {
        spinner.hidesWhenStopped = true
        contentView.addSubview(spinner)
    }

    private func setupVerifiedToggleLabel() {
        verifiedToggleLabel.font = FontSpec(.small, .light).font!
        verifiedToggleLabel.textColor = defaultTextColor
        verifiedToggleLabel.text = L10n.Localizable.Device.verified.capitalized
        verifiedToggleLabel.numberOfLines = 0
        contentView.addSubview(verifiedToggleLabel)
    }

    private func setupResetButton() {
        resetButton.setTitleColor(UIColor.accent(), for: .normal)
        resetButton.titleLabel?.font = FontSpec(.small, .light).font!
        resetButton.setTitle(ProfileDevicesDetail.ResetSession.title.capitalized, for: [])
        resetButton.addTarget(self, action: #selector(ProfileClientViewController.onResetTapped(_:)), for: .touchUpInside)
        resetButton.accessibilityIdentifier = "reset session"
        contentView.addSubview(resetButton)
    }

    private func setupDebugMenuButton() {
        guard Bundle.developerModeEnabled else { return }
        let debugButton = ButtonWithLargerHitArea()
        debugButton.setTitleColor(UIColor.accent(), for: .normal)
        debugButton.titleLabel?.font = FontSpec(.small, .light).font!
        debugButton.setTitle("Debug Menu", for: [])
        debugButton.addTarget(self, action: #selector(ProfileClientViewController.onShowDebugActions(_:)), for: .touchUpInside)
        contentView.addSubview(debugButton)
        debugMenuButton = debugButton
    }

    private func setupVerifiedToggle() {
        verifiedToggle.isOn = viewModel.userClient.verified
        verifiedToggle.addTarget(self, action: #selector(ProfileClientViewController.onTrustChanged(_:)), for: .valueChanged)
        contentView.addSubview(verifiedToggle)
    }

    private func updateIDLabel() {
        let fingerprintSmallMonospaceFont = fingerprintSmallFont.monospaced()
        let fingerprintSmallBoldMonospaceFont = fingerprintSmallBoldFont.monospaced()

        IDLabel.attributedText = viewModel.userClient.attributedRemoteIdentifier(
            [.font: fingerprintSmallMonospaceFont],
            boldAttributes: [.font: fingerprintSmallBoldMonospaceFont],
            uppercase: true
        )
    }

    private func updateFingerprintLabel(with data: Data?) {
        let fingerprintMonospaceFont = fingerprintFont.monospaced()
        let fingerprintBoldMonospaceFont = fingerprintBoldFont.monospaced()

        if let attributedFingerprint = data?.attributedFingerprint(
            attributes: [.font: fingerprintMonospaceFont],
            boldAttributes: [.font: fingerprintBoldMonospaceFont],
            uppercase: false) {
            fullIDLabel.attributedText = attributedFingerprint
            spinner.stopAnimating()
        } else {
            fullIDLabel.attributedText = NSAttributedString(string: "")
            spinner.startAnimating()
        }
    }

    private func setupAccessibility() {
        typealias ClientList = L10n.Accessibility.ClientsList
        typealias DeviceDetails = L10n.Accessibility.DeviceDetails

        if let deviceName = typeLabel.text {
            typeLabel.accessibilityLabel = "\(ClientList.DeviceName.description), \(deviceName)"
        }
        if let deviceId = IDLabel.text {
            IDLabel.accessibilityLabel = "\(ClientList.DeviceId.description), \(deviceId)"
        }
        if let keyFingerprint = fullIDLabel.text {
            fullIDLabel.accessibilityLabel = "\(ClientList.KeyFingerprint.description), \(keyFingerprint)"
        }

        descriptionTextView.isAccessibilityElement = true
        descriptionTextView.accessibilityTraits = .link
        descriptionTextView.accessibilityIdentifier = "description text"

        verifiedToggle.accessibilityLabel = DeviceDetails.Verified.description
        verifiedToggleLabel.isAccessibilityElement = false
    }

    // MARK: Setup Constraints

    private func createConstraints() {
        let topMargin = UIScreen.safeArea.top > 0 ? UIScreen.safeArea.top : 26.0

        [contentView,
         descriptionTextView,
         separatorLineView,
         typeLabel,
         fullIDLabel,
         verifiedToggle,
         verifiedToggleLabel,
         resetButton,
         backButton,
         spinner,
         IDLabel].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        NSLayoutConstraint.activate([
            contentView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16),
            contentView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16),
            contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -32),
            contentView.topAnchor.constraint(greaterThanOrEqualTo: view.topAnchor, constant: 24),
            descriptionTextView.topAnchor.constraint(equalTo: contentView.topAnchor),
            descriptionTextView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            descriptionTextView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            descriptionTextView.bottomAnchor.constraint(equalTo: separatorLineView.topAnchor, constant: -24),
            separatorLineView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            separatorLineView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            separatorLineView.heightAnchor.constraint(equalToConstant: .hairline),

            typeLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            typeLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            typeLabel.topAnchor.constraint(equalTo: separatorLineView.bottomAnchor, constant: 24),
            IDLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            IDLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            IDLabel.topAnchor.constraint(equalTo: typeLabel.bottomAnchor, constant: -2),
            fullIDLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            fullIDLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            fullIDLabel.topAnchor.constraint(equalTo: IDLabel.bottomAnchor, constant: 24),

            verifiedToggle.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            verifiedToggle.topAnchor.constraint(equalTo: fullIDLabel.bottomAnchor, constant: 32),
            verifiedToggle.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -UIScreen.safeArea.bottom),
            verifiedToggleLabel.leftAnchor.constraint(equalTo: verifiedToggle.rightAnchor, constant: 10),
            verifiedToggleLabel.centerYAnchor.constraint(equalTo: verifiedToggle.centerYAnchor),
            resetButton.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            resetButton.centerYAnchor.constraint(equalTo: verifiedToggle.centerYAnchor),

            backButton.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: -8),
            backButton.topAnchor.constraint(equalTo: view.topAnchor, constant: topMargin),
            backButton.widthAnchor.constraint(equalToConstant: 32),
            backButton.heightAnchor.constraint(equalToConstant: 32),

            spinner.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            spinner.topAnchor.constraint(greaterThanOrEqualTo: IDLabel.bottomAnchor, constant: 24),
            spinner.bottomAnchor.constraint(lessThanOrEqualTo: verifiedToggle.bottomAnchor, constant: -32)
        ])

        if let debugMenuButton = debugMenuButton {
            [contentView, descriptionTextView, debugMenuButton].forEach {
                $0.translatesAutoresizingMaskIntoConstraints = false
            }
            NSLayoutConstraint.activate([
                debugMenuButton.rightAnchor.constraint(equalTo: contentView.rightAnchor),
                debugMenuButton.leftAnchor.constraint(equalTo: contentView.leftAnchor),
                debugMenuButton.topAnchor.constraint(equalTo: descriptionTextView.bottomAnchor, constant: 10)
            ])
        }
    }

    // MARK: Actions

    @objc private func onBackTapped(_ sender: AnyObject) {
        presentingViewController?.dismiss(animated: true, completion: .none)
    }

    @objc private func onShowMyDeviceTapped(_ sender: AnyObject) {
        guard let session = ZMUserSession.shared(),
              let selfUserClient = session.selfUserClient else { return }

        let selfClientController = SettingsClientViewController(userClient: selfUserClient,
                                                                userSession: session,
                                                                fromConversation: fromConversation)

        let navigationControllerWrapper = selfClientController.wrapInNavigationController(setBackgroundColor: true)

        navigationControllerWrapper.modalPresentationStyle = .currentContext
        present(navigationControllerWrapper, animated: true, completion: .none)
    }

    @objc
    private func onTrustChanged(_ sender: AnyObject) {
        guard let userSession = ZMUserSession.shared() else { return }
        userSession.enqueue({ [weak self] in
            guard let weakSelf = self else { return }
            let selfClient = userSession.selfUserClient
            if weakSelf.verifiedToggle.isOn {
                selfClient?.trustClient(weakSelf.viewModel.userClient)
            } else {
                selfClient?.ignoreClient(weakSelf.viewModel.userClient)
            }
        }, completionHandler: { [weak self] in
            guard let weakSelf = self else { return }

            weakSelf.verifiedToggle.isOn = weakSelf.viewModel.userClient.verified
        })
    }

    @objc private func onResetTapped(_ sender: AnyObject) {
        viewModel.userClient.resetSession()
        isLoadingViewVisible = true
    }

    @objc private func onShowDebugActions(_ sender: AnyObject) {
        let actionSheet = UIAlertController(
            title: "Debug actions",
            message: "⚠️ will cause decryption errors ⚠️",
            preferredStyle: .actionSheet
        )

        actionSheet.addAction(
            UIAlertAction(
                title: "Delete Session",
                style: .default,
                handler: { [weak self] (_) in
                    self?.onDeleteDeviceTapped()
                }
            )
        )

        actionSheet.addAction(
            UIAlertAction(
                title: "Corrupt Session",
                style: .default,
                handler: { [weak self] (_) in
                    self?.onCorruptSessionTapped()
                }
            )
        )

        actionSheet.addAction(
            UIAlertAction(
                title: "Duplicate client",
                style: .default,
                handler: {[weak self] _ in
                    self?.onDuplicateClientTapped()
                }
            )
        )

        actionSheet.addAction(.cancel())

        present(actionSheet, animated: true)
    }

    @objc
    private func onDeleteDeviceTapped() {
        let clientObjectID = self.viewModel.userClient.objectID
        let sync = viewModel.userClient.managedObjectContext!.zm_sync!
        Task { [self] in
            let client = await sync.perform { try! sync.existingObject(with: clientObjectID) as! UserClient }
            await client.deleteClientAndEndSession()
            _ = await sync.perform { sync.saveOrRollback() }
            await MainActor.run {
                presentingViewController?.dismiss(animated: true, completion: .none)
            }
        }
    }

    @objc
    private func onCorruptSessionTapped() {
        let sync = viewModel.userClient.managedObjectContext!.zm_sync!
        let selfClientObjectID = ZMUser.selfUser()?.selfClient()?.objectID
        let userClientObjectID = viewModel.userClient.objectID
        Task {
            let client = await sync.perform { try! sync.existingObject(with: userClientObjectID) as! UserClient }
            let selfClient = await sync.perform { try! sync.existingObject(with: selfClientObjectID!) as! UserClient }
            _ = await selfClient.establishSessionWithClient(client, usingPreKey: "pQABAQACoQBYIBi1nXQxPf9hpIp1K1tBOj/tlBuERZHfTMOYEW38Ny7PA6EAoQBYIAZbZQ9KtsLVc9VpHkPjYy2+Bmz95fyR0MGKNUqtUUi1BPY=")
            await sync.perform { sync.saveOrRollback() }
            await MainActor.run {
                presentingViewController?.dismiss(animated: true, completion: .none)
            }
        }
    }

    private func onDuplicateClientTapped() {
        let context = viewModel.userClient.managedObjectContext!.zm_sync!

        context.performAndWait {
            guard
                let userID = viewModel.userClient.user?.remoteIdentifier,
                let domain = viewModel.userClient.user?.domain ?? BackendInfo.domain
            else {
                return
            }

            let user = ZMUser.fetch(
                with: userID,
                domain: domain,
                in: context
            )

            let duplicate = UserClient.insertNewObject(in: context)
            duplicate.remoteIdentifier = viewModel.userClient.remoteIdentifier
            duplicate.user = user

            context.saveOrRollback()
        }
    }

}

// MARK: - UserClientObserver

extension ProfileClientViewController: UserClientObserver {

    func userClientDidChange(_ changeInfo: UserClientChangeInfo) {

        if changeInfo.sessionHasBeenReset {
            let alert = UIAlertController(title: "", message: L10n.Localizable.Self.Settings.DeviceDetails.ResetSession.success, preferredStyle: .alert)
            let okAction = UIAlertAction(title: L10n.Localizable.General.ok, style: .destructive, handler: nil)
            alert.addAction(okAction)
            present(alert, animated: true, completion: .none)
            isLoadingViewVisible = false
        }
    }

}

// MARK: - UITextViewDelegate

extension ProfileClientViewController: UITextViewDelegate {

    func textView(_ textView: UITextView, shouldInteractWith url: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        guard url == .wr_fingerprintHowToVerify else { return false }
        url.openInApp(above: self)
        return false
    }
}
