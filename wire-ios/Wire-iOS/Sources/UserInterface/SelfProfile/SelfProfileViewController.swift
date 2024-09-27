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

import UIKit
import WireCommonComponents
import WireDesign
import WireReusableUIComponents
import WireSyncEngine

// MARK: - SelfProfileViewController

/// The first page of the user settings.

final class SelfProfileViewController: UIViewController {
    var userRightInterfaceType: UserRightInterface.Type
    var settingsCellDescriptorFactory: SettingsCellDescriptorFactory?
    var rootGroup: (SettingsControllerGeneratorType & SettingsInternalGroupCellDescriptorType)?

    // MARK: - Views

    private let settingsController: SettingsTableViewController
    private weak var accountSelectorView: AccountSelectorView?
    private let profileContainerView = UIView()
    private let profileHeaderViewController: ProfileHeaderViewController
    private let profileImagePicker = ProfileImagePickerManager()

    let userSession: UserSession
    private let accountSelector: AccountSelector?

    private lazy var activityIndicator = BlockingActivityIndicator(view: topViewController.view ?? view)

    // MARK: - AppLock

    private var callback: ResultHandler?

    // MARK: - Configuration

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        [.portrait]
    }

    // MARK: - Initialization

    /// Creates the settings screen with the specified user and permissions.
    /// - parameter selfUser: The current user.
    /// - parameter userRightInterfaceType: The type of object to determine the user permissions.

    init(
        selfUser: SettingsSelfUser,
        userRightInterfaceType: UserRightInterface.Type,
        userSession: UserSession,
        accountSelector: AccountSelector?
    ) {
        self.userSession = userSession
        self.accountSelector = accountSelector

        // Create the settings hierarchy

        let settingsPropertyFactory = SettingsPropertyFactory(userSession: userSession, selfUser: selfUser)

        let settingsCellDescriptorFactory = SettingsCellDescriptorFactory(
            settingsPropertyFactory: settingsPropertyFactory,
            userRightInterfaceType: userRightInterfaceType
        )

        let rootGroup = settingsCellDescriptorFactory.rootGroup(
            isTeamMember: selfUser.isTeamMember,
            userSession: userSession
        )

        self.settingsController = rootGroup.generateViewController()! as! SettingsTableViewController

        var options: ProfileHeaderViewController.Options
        options = selfUser.isTeamMember ? [.allowEditingAvailability] : [.hideAvailability]
        if userRightInterfaceType.selfUserIsPermitted(to: .editProfilePicture) {
            options.insert(.allowEditingProfilePicture)
        }
        self.profileHeaderViewController = ProfileHeaderViewController(
            user: selfUser,
            viewer: selfUser,
            conversation: .none,
            options: options,
            userSession: userSession,
            isUserE2EICertifiedUseCase: userSession.isUserE2EICertifiedUseCase,
            isSelfUserE2EICertifiedUseCase: userSession.isSelfUserE2EICertifiedUseCase
        )

        self.userRightInterfaceType = userRightInterfaceType
        self.settingsCellDescriptorFactory = settingsCellDescriptorFactory
        self.rootGroup = rootGroup

        super.init(nibName: nil, bundle: nil)
        settingsPropertyFactory.delegate = self

        if selfUser.isTeamMember {
            userSession.enqueue {
                selfUser.refreshTeamData()
            }
        }
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(userDidTapProfileImage))
        profileHeaderViewController.imageView.addGestureRecognizer(tapGestureRecognizer)

        addChild(profileHeaderViewController)
        profileContainerView.addSubview(profileHeaderViewController.view)
        view.addSubview(profileContainerView)
        profileHeaderViewController.didMove(toParent: self)

        addChild(settingsController)
        view.addSubview(settingsController.view)
        settingsController.didMove(toParent: self)

        settingsController.tableView.isScrollEnabled = false

        createConstraints()
        setupAccessibility()
        view.backgroundColor = SemanticColors.View.backgroundDefault
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureAccountTitle()
        navigationItem.rightBarButtonItem = UIBarButtonItem.closeButton(action: UIAction { [weak self] _ in
            self?.presentingViewController?.dismiss(animated: true)
        }, accessibilityLabel: L10n.Localizable.General.close)
        navigationController?.navigationBar.backgroundColor = SemanticColors.View.backgroundDefault
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if !presentNewLoginAlertControllerIfNeeded() {
            presentUserSettingChangeControllerIfNeeded()
        }
    }

    private func configureAccountTitle() {
        if let accounts = SessionManager.shared?.accountManager.accounts, accounts.count > 1 {
            let accountSelectorView = AccountSelectorView()
            accountSelectorView.delegate = self
            accountSelectorView.accounts = accounts
            navigationItem.titleView = accountSelectorView
            self.accountSelectorView = accountSelectorView
        } else {
            setupNavigationBarTitle(L10n.Localizable.Self.account)
        }
    }

    private func createConstraints() {
        profileHeaderViewController.view.translatesAutoresizingMaskIntoConstraints = false
        profileContainerView.translatesAutoresizingMaskIntoConstraints = false
        settingsController.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // profileContainerView
            profileContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            profileContainerView.topAnchor.constraint(equalTo: safeTopAnchor),
            profileContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            // profileView
            profileHeaderViewController.view.leadingAnchor.constraint(equalTo: profileContainerView.leadingAnchor),
            profileHeaderViewController.view.topAnchor.constraint(greaterThanOrEqualTo: profileContainerView.topAnchor),
            profileHeaderViewController.view.trailingAnchor.constraint(equalTo: profileContainerView.trailingAnchor),
            profileHeaderViewController.view.bottomAnchor
                .constraint(lessThanOrEqualTo: profileContainerView.bottomAnchor),
            profileHeaderViewController.view.centerYAnchor.constraint(equalTo: profileContainerView.centerYAnchor),

            // settingsControllerView
            settingsController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            settingsController.view.topAnchor.constraint(equalTo: profileContainerView.bottomAnchor),
            settingsController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            settingsController.view.bottomAnchor.constraint(equalTo: safeBottomAnchor),
        ])
    }

    private func setupAccessibility() {
        typealias AccountPage = L10n.Accessibility.AccountPage

        navigationItem.rightBarButtonItem?.accessibilityLabel = AccountPage.CloseButton.description
        navigationItem.backBarButtonItem?.accessibilityLabel = AccountPage.BackButton.description
    }

    // MARK: - Events

    @objc
    private func userDidTapProfileImage(_: UIGestureRecognizer) {
        guard userRightInterfaceType.selfUserIsPermitted(to: .editProfilePicture) else { return }

        let alertController = profileImagePicker.selectProfileImage()
        if let popoverPresentationController = alertController.popoverPresentationController {
            popoverPresentationController.sourceView = profileHeaderViewController.imageView.superview!
            popoverPresentationController.sourceRect = profileHeaderViewController.imageView.frame.insetBy(
                dx: -4,
                dy: -4
            )
        }
        present(alertController, animated: true)
    }

    override func accessibilityPerformEscape() -> Bool {
        dismiss(animated: true)
        return true
    }
}

// MARK: AccountSelectorViewDelegate

extension SelfProfileViewController: AccountSelectorViewDelegate {
    func accountSelectorView(_ view: AccountSelectorView, didSelect account: Account) {
        guard SessionManager.shared?.accountManager.selectedAccount != account else { return }

        presentingViewController?.dismiss(animated: true) {
            AppDelegate.shared.mediaPlaybackManager?
                .stop() // there must be another more appropriate place for this line
            self.accountSelector?.switchTo(account: account)
        }
    }
}

// MARK: SettingsPropertyFactoryDelegate

extension SelfProfileViewController: SettingsPropertyFactoryDelegate {
    private var topViewController: UIViewController! {
        navigationController!.topViewController
    }

    func asyncMethodDidStart(_: SettingsPropertyFactory) {
        // shown on SettingsTableViewController
        activityIndicator.start()
    }

    func asyncMethodDidComplete(_: SettingsPropertyFactory) {
        activityIndicator.stop()
    }

    /// Create or delete custom passcode when appLock option did change
    /// If custom passcode is not enabled, no action is taken
    ///
    /// - Parameters:
    ///   - settingsPropertyFactory: caller of this delegate method
    ///   - newValue: new value of app lock option
    ///   - callback: callback for PasscodeSetupViewController
    func appLockOptionDidChange(
        _ settingsPropertyFactory: SettingsPropertyFactory,
        newValue: Bool,
        callback: @escaping ResultHandler
    ) {
        // There is an additional check for the simulator because there's no way to disable the device passcode on the
        // simulator. We need it for testing.
        guard AuthenticationType
            .current == .unavailable || (UIDevice.isSimulator && AuthenticationType.current == .passcode) else {
            callback(newValue)
            return
        }

        guard newValue else {
            try? userSession.deleteAppLockPasscode()
            callback(newValue)
            return
        }

        self.callback = callback
        let passcodeSetupViewController = PasscodeSetupViewController(
            context: .createPasscode,
            callback: callback
        )
        passcodeSetupViewController.passcodeSetupViewControllerDelegate = self

        let keyboardAvoidingViewController = KeyboardAvoidingViewController(viewController: passcodeSetupViewController)

        let wrappedViewController = keyboardAvoidingViewController
            .wrapInNavigationController(navigationBarClass: TransparentNavigationBar.self)

        let closeItem = passcodeSetupViewController.closeItem

        keyboardAvoidingViewController.navigationItem.leftBarButtonItem = closeItem

        wrappedViewController.presentationController?.delegate = passcodeSetupViewController

        if UIDevice.current.userInterfaceIdiom == .pad {
            wrappedViewController.modalPresentationStyle = .popover
            present(wrappedViewController, animated: true)
        } else {
            UIApplication.shared.topmostViewController()?.present(wrappedViewController, animated: true)
        }
    }
}

// MARK: PasscodeSetupViewControllerDelegate

extension SelfProfileViewController: PasscodeSetupViewControllerDelegate {
    func passcodeSetupControllerDidFinish() {
        // no-op
    }

    func passcodeSetupControllerWasDismissed() {
        // refresh options applock switch
        (topViewController as? SettingsTableViewController)?.refreshData()
    }
}
