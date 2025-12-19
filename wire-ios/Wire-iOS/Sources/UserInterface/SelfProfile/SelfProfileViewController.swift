//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

import SwiftUI
import WireAccountImageUI
import WireCommonComponents
import WireDesign
import WireDomainPackage
import WireFoundation
import WireIndividualToTeamMigrationUI
import WireMainNavigationUI
import WireMultiBackendUI
import WireNetwork
import WireReusableUIComponents
import WireSettingsUI
import WireSyncEngine
import WireUtilities

// sourcery: AutoMockable
protocol SelfProfileAccountManager {
    func sortedAccounts() -> [Account]
    var selectedAccount: Account? { get }
}

/// The first page of the user settings.
final class SelfProfileViewController: UIViewController {

    let userSession: UserSession
    private let userRightInterfaceType: UserRightInterface.Type

    // MARK: - Views

    private var bottomController: UIViewController!
    private var settingsController: SettingsTableViewController?
    private var accountSwitcherViewController: AccountSwitcherHostingController?
    private let profileLayoutGuide = UILayoutGuide()
    private var profileLayoutGuideViewTopConstraint = NSLayoutConstraint()
    private var profileLayoutGuideBannerTopConstraint = NSLayoutConstraint()
    private let profileHeaderViewController: ProfileHeaderViewController
    private let profileImagePicker = ProfileImagePickerManager()
    private var teamMigrationBanner: UIViewController?

    private let accountSelector: AccountSelector?
    let mainCoordinator: AnyMainCoordinator
    private let selfProfileViewsMonitor: SelfProfileViewsMonitor
    private let analyticsEventTracker: (any AnalyticsEventTrackerProtocol)?
    private let accountManager: (any SelfProfileAccountManager)?

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
        mainCoordinator: AnyMainCoordinator,
        analyticsEventTracker: (any AnalyticsEventTrackerProtocol)?,
        accountManager: (any SelfProfileAccountManager)?
    ) {
        self.accountSelector = accountSelector
        self.mainCoordinator = mainCoordinator
        self.analyticsEventTracker = analyticsEventTracker
        self.accountManager = accountManager

        // Create the settings hierarchy
        let settingsPropertyFactory = SettingsPropertyFactory(
            userSession: userSession,
            selfUser: selfUser,
            trackingManager: nil
        )

        let settingsCoordinator = SettingsCoordinator(mainCoordinator: mainCoordinator)
        let settingsCellDescriptorFactory = SettingsCellDescriptorFactory(
            settingsPropertyFactory: settingsPropertyFactory,
            userRightInterfaceType: userRightInterfaceType,
            settingsCoordinator: AnySettingsCoordinator(settingsCoordinator: settingsCoordinator),
            localDomain: userSession.resolvedBackendMetadata.domain,
            isFederationEnabled: userSession.resolvedBackendMetadata.isFederationEnabled
        )

        let rootGroup = settingsCellDescriptorFactory.rootGroup(userSession: userSession)

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
        self.selfProfileViewsMonitor = SelfProfileViewsMonitorImplementation()
        super.init(nibName: nil, bundle: nil)

        if selfUser.isTeamMember {
            userSession.enqueue {
                selfUser.refreshTeamData()
            }
        } else if
            let backendInfoApiVersion = userSession.resolvedBackendMetadata.apiVersion,
            let apiVersion = WireNetwork.APIVersion(rawValue: UInt(backendInfoApiVersion.rawValue)),
            apiVersion >= .v7 {
            let accentColor = WireAccentColor(rawValue: selfUser.accentColorValue) ?? .default
            let upgradeBanner = SelfProfileViewCallToActionBanner { [weak self] in
                self?.onTeamCreationBannerInteraction(apiVersion: apiVersion)
            }.environment(\.wireAccentColor, accentColor)
            self.teamMigrationBanner = UIHostingController(rootView: upgradeBanner)
            teamMigrationBanner?.view.backgroundColor = .clear
        }

        let accountSwitcherViewController = makeAccountSwitcherViewController(
            settingsCellDescriptorFactory: settingsCellDescriptorFactory
        )
        self.bottomController = accountSwitcherViewController
        self.accountSwitcherViewController = accountSwitcherViewController
    }

    private func makeAccountSwitcherViewController(settingsCellDescriptorFactory: SettingsCellDescriptorFactory)
        -> AccountSwitcherHostingController {
        var options = [Option.addAccountOption(action: {
            settingsCellDescriptorFactory
                .addAccountOrTeamCell().select(.none, sender: UIView())
        })]
        if userSession.selfUser.canManageTeam == true {
            options.append(Option.manageTeamOption(action: { [weak self] in
                let controllerToShow = BrowserViewController(url: URL.manageTeam(source: .settings))
                controllerToShow.modalPresentationCapturesStatusBarAppearance = true
                self?.present(controllerToShow, animated: true, completion: .none)
            }))
        }

        let otherAccounts = (accountManager?.sortedAccounts() ?? [])
            .filter {
                !$0.isEqual(accountManager?.selectedAccount)
            }
            .map { account in
                account.toUIModel(action: { [weak self] in
                    self?.handleAccountSelected(account)
                })
            }

        let appSwitcherController = AccountSwitcherHostingController(
            otherAccounts: otherAccounts,
            options: options
        )
        appSwitcherController.sizingOptions = .intrinsicContentSize
        return appSwitcherController
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

        addChild(bottomController)
        view.addSubview(bottomController.view)
        bottomController.didMove(toParent: self)

        settingsController?.tableView.isScrollEnabled = false

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
        selfProfileViewsMonitor.onDidViewSelfProfile()
        navigationItem.rightBarButtonItem = UIBarButtonItem.closeButton(action: UIAction { [weak self] _ in
            self?.dismiss()
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

    private func createConstraints() {
        profileHeaderViewController.view.translatesAutoresizingMaskIntoConstraints = false
        bottomController.view.translatesAutoresizingMaskIntoConstraints = false

        profileLayoutGuideViewTopConstraint = profileLayoutGuide.topAnchor
            .constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)

        if let teamMigrationBanner {
            teamMigrationBanner.view.translatesAutoresizingMaskIntoConstraints = false
            profileLayoutGuideBannerTopConstraint = profileLayoutGuide.topAnchor
                .constraint(equalTo: teamMigrationBanner.view.bottomAnchor)
            NSLayoutConstraint.activate([

                // teamMigrationBanner
                teamMigrationBanner.view.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
                teamMigrationBanner.view.topAnchor.constraint(
                    equalTo: view.safeAreaLayoutGuide.topAnchor,
                    constant: 20
                ),
                teamMigrationBanner.view.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
                profileLayoutGuideBannerTopConstraint
            ])
        } else {
            profileLayoutGuideViewTopConstraint.isActive = true
        }

        NSLayoutConstraint.activate([

            // profileLayoutGuide
            profileLayoutGuide.bottomAnchor
                .constraint(equalTo: bottomController.view.topAnchor),

            // profileView
            profileHeaderViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            profileHeaderViewController.view.topAnchor.constraint(greaterThanOrEqualTo: profileLayoutGuide.topAnchor),
            profileHeaderViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            profileHeaderViewController.view.bottomAnchor
                .constraint(lessThanOrEqualTo: profileLayoutGuide.bottomAnchor),
            profileHeaderViewController.view.centerYAnchor.constraint(equalTo: profileLayoutGuide.centerYAnchor),

            // settingsControllerView
            bottomController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomController.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    private func setupAccessibility() {
        typealias AccountPage = L10n.Accessibility.AccountPage

        navigationItem.rightBarButtonItem?.accessibilityLabel = AccountPage.CloseButton.description
        navigationItem.backBarButtonItem?.accessibilityLabel = AccountPage.BackButton.description
    }

    // MARK: - Events

    private func onTeamCreationBannerInteraction(
        apiVersion: WireNetwork.APIVersion
    ) {
        let sessionContextProvider = userSession.contextProvider
        let user = ZMUser.selfUser(inUserSession: sessionContextProvider)
        guard let userName = user.normalizedName,
              let useCase = SessionManager.shared?.activeUserSession?
              .createIndividualToTeamMigrationUseCase() else {
            return
        }
        userDidTapCreateTeam(useCase: useCase, userName: userName)
    }

    func triggerCreateTeamFlow() {
        if let backendInfoApiVersion = userSession.resolvedBackendMetadata.apiVersion,
           let apiVersion = APIVersion(rawValue: UInt(backendInfoApiVersion.rawValue)),
           apiVersion >= .v7 {
            onTeamCreationBannerInteraction(apiVersion: apiVersion)
        }
    }

    private func userDidTapCreateTeam(useCase: any IndividualToTeamMigrationUseCaseProtocol, userName: String) {

        analyticsEventTracker?.trackEvent(.UI.personalToTeamMigrationCTA)

        let analyticsEventTracker = analyticsEventTracker.map {
            AccountMigrationAnalyticsTracker(analyticsEventTracker: $0)
        }

        let viewController = IndividualToTeamMigrationViewController(
            privacyPolicyURL: WireURLs.shared.privacyPolicy.absoluteString,
            termsOfUseURL: WireURLs.shared.legal.absoluteString,
            useCase: useCase,
            userProfileName: userName,
            analyticsEventTracker: analyticsEventTracker,
            actionCallback: { [weak self] action in
                Task { [weak self] in
                    await MainActor.run { [weak self] in
                        guard let self else { return }
                        switch action {
                        case .cancel:
                            presentedViewController?.dismiss(animated: true)
                        case .toLearnMoreAboutPlans:
                            _ = WireURLs.shared.wireEnterpriseInfo.open()
                        case .completionDismiss:
                            dismissIndividualToTeamMigrationBanner()
                            presentedViewController?.dismiss(animated: true)
                        case .completionGoToConversations:
                            dismissIndividualToTeamMigrationBanner()
                            if let presentingViewController {
                                presentingViewController.dismiss(animated: true)
                            } else {
                                presentedViewController?.dismiss(animated: true)
                            }
                        case .completionGoToTeamManagement:
                            dismissIndividualToTeamMigrationBanner()
                            if let presentingViewController {
                                presentingViewController.dismiss(animated: true) {
                                    URL.manageTeam(source: .settings).open()
                                }
                            } else {
                                presentedViewController?.dismiss(animated: true)
                            }
                        }
                    }
                }
            }
        )
        viewController.modalPresentationStyle = .formSheet
        viewController.presentationController?.delegate = viewController

        if presentedViewController != nil {
            dismiss(animated: true) {
                self.present(viewController, animated: true)
            }
        } else {
            present(viewController, animated: true)
        }
    }

    private func dismissIndividualToTeamMigrationBanner() {
        teamMigrationBanner?.willMove(toParent: nil)
        teamMigrationBanner?.view.removeFromSuperview()
        teamMigrationBanner?.removeFromParent()
        teamMigrationBanner = nil
        profileLayoutGuideBannerTopConstraint.isActive = false
        profileLayoutGuideViewTopConstraint.isActive = true
    }

    private func navigateToTeam() {
        URL.manageTeam(source: .settings).open()
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

    private func dismiss() {
        sendDismissAnalyticsEventIfNeeded()
        presentingViewController?.dismiss(animated: true)
    }

    private func sendDismissAnalyticsEventIfNeeded() {
        // only when the banner was shown to the user
        guard teamMigrationBanner != nil else { return }

        analyticsEventTracker?.trackEvent(.UI.dismissedSelfProfileWithToTeamMigrationBanner)
    }

    override func accessibilityPerformEscape() -> Bool {
        sendDismissAnalyticsEventIfNeeded()
        dismiss(animated: true)
        return true
    }

    private func handleAccountSelected(_ account: Account) {
        guard accountManager?.selectedAccount != account else { return }

        sendDismissAnalyticsEventIfNeeded()
        presentingViewController?.dismiss(animated: true) {
            if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                appDelegate.mediaPlaybackManager?.stop()
            }
            self.accountSelector?.switchTo(account: account)
        }
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate

extension SelfProfileViewController: UIAdaptivePresentationControllerDelegate {

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        sendDismissAnalyticsEventIfNeeded()
    }
}

// MARK: - Notifications

public extension Notification.Name {
    // Used to notify the app that the user has viewed their own profile
    static let userDidViewSelfProfile = Notification.Name("userDidViewSelfProfile")
}

extension Account {
    func toUIModel(action: @escaping () -> Void) -> AccountUIModel {
        let avatarSource: WireAccountImageUI.AccountImageSource
        if let imageData,
           let avatarImage = UIImage(data: imageData) {
            avatarSource = .image(avatarImage)
        } else {
            let personName = PersonName.person(
                withName: userName,
                schemeTagger: nil
            )
            avatarSource = .text(personName.initials)
        }
        return AccountUIModel(
            avatarSource: avatarSource,
            name: userName,
            handle: handle,
            teamName: teamName,
            backendName: backendName,
            action: action
        )
    }
}
