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

// TODO: [WPB-11951] when opening self profile ensure these alerts are shown and also don't block each other
// - alert that new devices have been added
// - alert about read receipts enabled

import SwiftUI
import UIKit
import WireCommonComponents
import WireDesign
import WireIndividualToTeamMigrationUI
import WireMainNavigationUI
import WireReusableUIComponents
import WireSettingsUI
import WireSyncEngine

/// The first page of the user settings.
final class SelfProfileViewController: UIViewController {

    let userSession: UserSession
    private let userRightInterfaceType: UserRightInterface.Type

    // MARK: - Views

    private let settingsController: SettingsTableViewController
    private weak var accountSelectorView: AccountSelectorView?
    private let profileLayoutGuide = UILayoutGuide()
    private let profileHeaderViewController: ProfileHeaderViewController
    private let profileImagePicker = ProfileImagePickerManager()
    private var teamMigrationBanner: UIViewController?
    

    private let accountSelector: AccountSelector?
    let mainCoordinator: AnyMainCoordinator

    // MARK: - Configuration

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        [.portrait]
    }

    // MARK: - Initialization

    init(
        selfUser: SettingsSelfUser,
        userRightInterfaceType: UserRightInterface.Type,
        userSession: UserSession,
        accountSelector: AccountSelector?,
        trackingManager: TrackingManager?,
        mainCoordinator: AnyMainCoordinator
    ) {
        self.accountSelector = accountSelector
        self.mainCoordinator = mainCoordinator
        
        // Create the settings hierarchy
        let settingsPropertyFactory = SettingsPropertyFactory(
            userSession: userSession,
            selfUser: selfUser,
            trackingManager: trackingManager
        )
        
        let settingsCoordinator = SettingsCoordinator(mainCoordinator: mainCoordinator)
        let settingsCellDescriptorFactory = SettingsCellDescriptorFactory(
            settingsPropertyFactory: settingsPropertyFactory,
            userRightInterfaceType: userRightInterfaceType,
            settingsCoordinator: AnySettingsCoordinator(settingsCoordinator: settingsCoordinator)
        )
        
        let rootGroup = settingsCellDescriptorFactory.rootGroup(userSession: userSession)
        
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
        
        self.userSession = userSession
        self.userRightInterfaceType = userRightInterfaceType
        
        super.init(nibName: nil, bundle: nil)

        if selfUser.isTeamMember {
            userSession.enqueue {
                selfUser.refreshTeamData()
            }
        } else {
            // TODO: [WPB-11270] show banner
//            teamMigrationBanner = SelfProfileViewCallToActionBannerHostingController(
//               actionCallback: { [weak self] _ in
//                   self?.userDidTapCreateTeam()
//               }
//           )
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
        view.addLayoutGuide(profileLayoutGuide)
        view.addSubview(profileHeaderViewController.view)
        profileHeaderViewController.didMove(toParent: self)

        addChild(settingsController)
        view.addSubview(settingsController.view)
        settingsController.didMove(toParent: self)

        settingsController.tableView.isScrollEnabled = false

        if let teamMigrationBanner {
            addChild(teamMigrationBanner)
            view.addSubview(teamMigrationBanner.view)
            teamMigrationBanner.didMove(toParent: self)
        }

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
        navigationItem.backButtonDisplayMode = .minimal
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
        settingsController.view.translatesAutoresizingMaskIntoConstraints = false
    
        if let teamMigrationBanner {
            teamMigrationBanner.view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                

                // teamMigrationBanner
                teamMigrationBanner.view.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
                teamMigrationBanner.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
                teamMigrationBanner.view.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
                
                profileLayoutGuide.topAnchor.constraint(equalTo: teamMigrationBanner.view.bottomAnchor)
            ])

        } else {
            profileLayoutGuide.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        }

        NSLayoutConstraint.activate([
            
            // profileLayoutGuide
            profileLayoutGuide.bottomAnchor.constraint(equalTo: settingsController.view.topAnchor),
            
            // profileView
            profileHeaderViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            profileHeaderViewController.view.topAnchor.constraint(greaterThanOrEqualTo: profileLayoutGuide.topAnchor),
            profileHeaderViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            profileHeaderViewController.view.bottomAnchor
                .constraint(lessThanOrEqualTo: profileLayoutGuide.bottomAnchor),
            profileHeaderViewController.view.centerYAnchor.constraint(equalTo: profileLayoutGuide.centerYAnchor),

            // settingsControllerView
            settingsController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            settingsController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            settingsController.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    private func setupAccessibility() {
        typealias AccountPage = L10n.Accessibility.AccountPage

        navigationItem.rightBarButtonItem?.accessibilityLabel = AccountPage.CloseButton.description
        navigationItem.backBarButtonItem?.accessibilityLabel = AccountPage.BackButton.description
    }

    // MARK: - Events

    private func onTeamCreationBannerInteraction(_ action: SelfProfileViewCallToActionBanner.Action) {
        switch action {
        case .createWireTeam:
            userDidTapCreateTeam()
        }
    }

    private func userDidTapCreateTeam() {
        // TODO: [WPB-11270] Present team creation flow
//        let vc = IndividualToTeamMigrationViewController(
//            features: ,
//            useCase: ,
//        )
//        present(vc, animated: true)
    }

    @objc
    private func userDidTapProfileImage(_ sender: UIGestureRecognizer) {
        guard userRightInterfaceType.selfUserIsPermitted(to: .editProfilePicture) else { return }

        let imageView = profileHeaderViewController.imageView
        let alertController = profileImagePicker.selectProfileImage(
            popoverConfiguration: .sourceView(sourceView: imageView, sourceRect: .null)
        )
        if let popoverPresentationController = alertController.popoverPresentationController {
            popoverPresentationController.sourceView = imageView
        }
        present(alertController, animated: true)
    }

    override func accessibilityPerformEscape() -> Bool {
        dismiss(animated: true)
        return true
    }
}

// MARK: - AccountSelectorViewDelegate

extension SelfProfileViewController: AccountSelectorViewDelegate {

    func accountSelectorView(_ view: AccountSelectorView, didSelect account: Account) {
        guard SessionManager.shared?.accountManager.selectedAccount != account else { return }

        presentingViewController?.dismiss(animated: true) {
            if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                appDelegate.mediaPlaybackManager?.stop()
            }
            self.accountSelector?.switchTo(account: account)
        }
    }
}
