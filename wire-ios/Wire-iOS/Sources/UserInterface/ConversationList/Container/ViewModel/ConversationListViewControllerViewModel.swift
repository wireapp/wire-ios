//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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
import UserNotifications
import WireAccountImageUI
import WireCommonComponents
import WireDataModel
import WireDomain
import WireFoundation
import WireLogging
import WireMainNavigationUI
import WireReusableUIComponents
import WireSyncEngine

typealias Completion = () -> Void
typealias ResultHandler = (_ succeeded: Bool) -> Void

protocol ConversationListContainerViewModelDelegate: AnyObject {

    func conversationListViewControllerViewModel(
        _ viewModel: ConversationListViewController.ViewModel,
        didUpdate accountImageSource: WireAccountImageUI.AccountImageSource
    )

    func conversationListViewControllerViewModel(
        _ viewModel: ConversationListViewController.ViewModel,
        didUpdate selfUserStatus: UserStatus
    )

    func showNoContactLabel(animated: Bool)
    func hideNoContactLabel(animated: Bool)
    @MainActor
    func showPermissionDeniedViewController()

    @MainActor
    func refreshAccountImageViewNotificationBadge()

    @discardableResult
    func selectOnListContentController(
        _ conversation: ZMConversation!,
        scrollTo message: ZMConversationMessage?,
        focusOnView focus: Bool,
        animated: Bool
    ) -> Bool

    func conversationListViewControllerViewModelRequiresUpdatingLegalHoldIndictor(
        _ viewModel: ConversationListViewController
            .ViewModel
    )

    func conversationListViewControllerViewModelDidReloadContent(
        _ viewModel: ConversationListViewController.ViewModel
    )
}

extension ConversationListViewController {

    final class ViewModel: NSObject {

        weak var viewController: ConversationListContainerViewModelDelegate? {
            didSet {
                guard viewController != nil else { return }

                updateNoConversationVisibility(animated: false)
                showPushPermissionDeniedDialogIfNeeded()
            }
        }

        let account: Account

        private(set) var selfUserStatus: UserStatus {
            didSet { viewController?.conversationListViewControllerViewModel(self, didUpdate: selfUserStatus) }
        }

        private(set) var accountImageSource: WireAccountImageUI.AccountImageSource = .text("") {
            didSet { viewController?.conversationListViewControllerViewModel(self, didUpdate: accountImageSource) }
        }

        let selfUserLegalHoldSubject: any SelfUserLegalHoldable
        let userSession: UserSession
        private let isSelfUserE2EICertifiedUseCase: IsSelfUserE2EICertifiedUseCaseProtocol
        private let notificationCenter: NotificationCenter

        var selectedConversation: ZMConversation?

        private let selfProfileViewsMonitor: SelfProfileViewsMonitor

        private var didBecomeActiveNotificationToken: NSObjectProtocol?
        private var accountUpdatedNotificationToken: NSObjectProtocol?
        private var e2eiCertificateChangedToken: NSObjectProtocol?
        private var initialSyncObserverToken: (any NSObjectProtocol)?

        private var userObservationToken: NSObjectProtocol?
        private var teamObservationToken: NSObjectProtocol?

        private var userDidViewSelfProfileToken: NSObjectProtocol?

        /// observer tokens which are assigned when viewDidLoad
        var allConversationsObserverToken: NSObjectProtocol?
        var connectionRequestsObserverToken: NSObjectProtocol?

        var actionsController: ConversationActionController?
        let mainCoordinator: any MainCoordinatorProtocol

        let shouldPresentNotificationPermissionHintUseCase: ShouldPresentNotificationPermissionHintUseCaseProtocol
        let didPresentNotificationPermissionHintUseCase: DidPresentNotificationPermissionHintUseCaseProtocol

        let getUserAccountImageSourceUseCase: any GetUserAccountImageSourceUseCaseProtocol

        public var hideProfileNotificationsBadge: Bool {
            if userSession.selfUser.isTeamMember {
                return true
            }
            guard let apiVersion = userSession.resolvedBackendMetadata.apiVersion,
                  apiVersion >= .v7 else {
                return true
            }

            return selfProfileViewsMonitor.didViewSelfProfile
        }

        init(
            account: Account,
            selfProfileViewsMonitor: SelfProfileViewsMonitor,
            selfUserLegalHoldSubject: SelfUserLegalHoldable,
            userSession: UserSession,
            isSelfUserE2EICertifiedUseCase: IsSelfUserE2EICertifiedUseCaseProtocol,
            notificationCenter: NotificationCenter = .default,
            mainCoordinator: some MainCoordinatorProtocol,
            getUserAccountImageSourceUseCase: any GetUserAccountImageSourceUseCaseProtocol
        ) {
            self.account = account
            self.selfProfileViewsMonitor = selfProfileViewsMonitor
            self.selfUserLegalHoldSubject = selfUserLegalHoldSubject
            self.userSession = userSession
            self.isSelfUserE2EICertifiedUseCase = isSelfUserE2EICertifiedUseCase
            self.selfUserStatus = .init(user: selfUserLegalHoldSubject, isE2EICertified: false)
            self.shouldPresentNotificationPermissionHintUseCase = ShouldPresentNotificationPermissionHintUseCase()
            self.didPresentNotificationPermissionHintUseCase = DidPresentNotificationPermissionHintUseCase()
            self.notificationCenter = notificationCenter
            self.mainCoordinator = mainCoordinator
            self.getUserAccountImageSourceUseCase = getUserAccountImageSourceUseCase
            super.init()

            updateE2EICertifiedStatus()
            updateAccountImage()
        }

        deinit {
            if let didBecomeActiveNotificationToken {
                notificationCenter.removeObserver(didBecomeActiveNotificationToken)
            }

            if let accountUpdatedNotificationToken {
                notificationCenter.removeObserver(accountUpdatedNotificationToken)
            }

            if let e2eiCertificateChangedToken {
                notificationCenter.removeObserver(e2eiCertificateChangedToken)
            }
            if let userDidViewSelfProfileToken {
                notificationCenter.removeObserver(userDidViewSelfProfileToken)
            }
        }
    }
}

extension ConversationListViewController.ViewModel {

    func setupObservers() {

        if let userSession = ZMUserSession.shared() {
            userObservationToken = userSession.addUserObserver(self, for: selfUserLegalHoldSubject)

            if let team = userSession.selfUser.membership?.team {
                team.requestImage()
                teamObservationToken = TeamChangeInfo.add(observer: self, for: team)
            }
        }

        updateObserverTokensForActiveTeam()

        didBecomeActiveNotificationToken = notificationCenter.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateE2EICertifiedStatus()
        }

        // This is a workaround:
        // When logging in the account image is generated before the account's
        // `userName` property is set. Therefore this observer listens for
        // account changes and once the userName is not empty, the image is
        // updated and the observation stopped.
        accountUpdatedNotificationToken = notificationCenter.addObserver(
            forName: AccountManagerDidUpdateAccountsNotificationName,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            // The notification is also triggered on logout, in which case accessing the account would crash.
            // Therefore only update the account if the accountManager's accounts still contains the instance we have.
            if let self,
               let accountManager = notification.object as? AccountManager,
               accountManager.account(with: account.userIdentifier) != nil,
               accountManager.selectedAccount == account,
               !account.userName.isEmpty {
                updateAccountImage()
                if let accountUpdatedNotificationToken {
                    notificationCenter.removeObserver(accountUpdatedNotificationToken)
                }
            }
        }

        e2eiCertificateChangedToken = notificationCenter.addObserver(
            forName: .e2eiCertificateChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateE2EICertifiedStatus()
        }

        userDidViewSelfProfileToken = notificationCenter.addObserver(
            forName: .userDidViewSelfProfile,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { [weak self] in
                await self?.viewController?.refreshAccountImageViewNotificationBadge()
            }
        }
    }

    private func updateAccountImage() {
        Task { @MainActor in
            do {
                accountImageSource = try await getUserAccountImageSourceUseCase.invoke(
                    user: userSession.selfUser,
                    userContext: userSession.contextProvider.viewContext,
                    account: account
                ).mapToAccountImageSource()
            } catch {
                WireLogger.ui.error("Failed to get user account image: \(String(reflecting: error))")
            }
        }
    }

    func savePendingLastRead() {
        userSession.enqueue {
            self.selectedConversation?.savePendingLastRead()
        }
    }

    /// Select a conversation and move the focus to the conversation view.
    ///
    /// - Parameters:
    ///   - conversation: the conversation to select
    ///   - message: scroll to  this message
    ///   - focus: focus on the view or not
    ///   - animated: perform animation or not
    ///   - completion: the completion block
    func select(
        conversation: ZMConversation,
        scrollTo message: ZMConversationMessage? = nil,
        focusOnView focus: Bool = false,
        animated: Bool = false
    ) {

        selectedConversation = conversation
        viewController?.selectOnListContentController(
            selectedConversation,
            scrollTo: message,
            focusOnView: focus,
            animated: animated
        )
    }

    /// show PushPermissionDeniedDialog when necessary
    ///
    /// - Returns: true if PushPermissionDeniedDialog is shown
    func showPushPermissionDeniedDialogIfNeeded() {
        // We only want to present the notification takeover when the user already has a handle
        // and is not coming from the registration flow (where we alreday ask for permissions).
        guard
            selfUserLegalHoldSubject.handle != nil,
            !AutomationHelper.sharedHelper.skipFirstLoginAlerts
        else { return }

        Task {
            let shouldPresent = await shouldPresentNotificationPermissionHintUseCase.invoke()
            if shouldPresent {
                await viewController?.showPermissionDeniedViewController()
                didPresentNotificationPermissionHintUseCase.invoke()
            }
        }
    }

    func updateE2EICertifiedStatus() {
        Task { @MainActor in
            do {
                selfUserStatus.isE2EICertified = try await isSelfUserE2EICertifiedUseCase.invoke()
            } catch {
                WireLogger.e2ei.error("failed to get E2EI certification status: \(error)")
            }
        }
    }
}

// MARK: - UserObserving

extension ConversationListViewController.ViewModel: UserObserving {

    @MainActor
    func userDidChange(_ changeInfo: UserChangeInfo) {

        if changeInfo.nameChanged || changeInfo.imageMediumDataChanged || changeInfo
            .imageSmallProfileDataChanged || changeInfo.teamsChanged {
            updateAccountImage()
        }

        if changeInfo.trustLevelChanged {
            selfUserStatus.isProteusVerified = changeInfo.user.isVerified
            updateE2EICertifiedStatus()
        }

        if changeInfo.legalHoldStatusChanged {
            viewController?.conversationListViewControllerViewModelRequiresUpdatingLegalHoldIndictor(self)
        }

        if changeInfo.availabilityChanged {
            selfUserStatus.availability = changeInfo.user.availability
        }

        if changeInfo.teamsChanged {
            if let team = changeInfo.user.membership?.team {
                teamObservationToken = TeamChangeInfo.add(observer: self, for: team)
            } else {
                teamObservationToken = nil
            }
        }
    }
}

// MARK: - TeamObserver

extension ConversationListViewController.ViewModel: TeamObserver {

    @MainActor
    func teamDidChange(_ changeInfo: TeamChangeInfo) {

        if changeInfo.imageDataChanged {
            updateAccountImage()
        }
    }
}
