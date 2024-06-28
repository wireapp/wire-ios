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
import UserNotifications
import WireCommonComponents
import WireDataModel
import WireSyncEngine

typealias Completion = () -> Void
typealias ResultHandler = (_ succeeded: Bool) -> Void

protocol ConversationListContainerViewModelDelegate: AnyObject {

    func conversationListViewControllerViewModel(
        _ viewModel: ConversationListViewController.ViewModel,
        didUpdate selfUserStatus: UserStatus
    )

    func showNoContactLabel(animated: Bool)
    func hideNoContactLabel(animated: Bool)
    func showNewsletterSubscriptionDialogIfNeeded(completionHandler: @escaping ResultHandler)
    @MainActor
    func showPermissionDeniedViewController()

    @discardableResult
    func selectOnListContentController(
        _ conversation: ZMConversation!,
        scrollTo message: ZMConversationMessage?,
        focusOnView focus: Bool,
        animated: Bool,
        completion: (() -> Void)?
    ) -> Bool

    func conversationListViewControllerViewModelRequiresUpdatingAccountView(_ viewModel: ConversationListViewController.ViewModel)
    func conversationListViewControllerViewModelRequiresUpdatingLegalHoldIndictor(_ viewModel: ConversationListViewController.ViewModel)
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

        let selfUserLegalHoldSubject: any SelfUserLegalHoldable
        let userSession: UserSession
        private let isSelfUserE2EICertifiedUseCase: IsSelfUserE2EICertifiedUseCaseProtocol
        private let notificationCenter: NotificationCenter

        var selectedConversation: ZMConversation?

        private var didBecomeActiveNotificationToken: NSObjectProtocol?
        private var e2eiCertificateChangedToken: NSObjectProtocol?
        private var initialSyncObserverToken: (any NSObjectProtocol)?
        private var userObservationToken: NSObjectProtocol?
        /// observer tokens which are assigned when viewDidLoad
        var allConversationsObserverToken: NSObjectProtocol?
        var connectionRequestsObserverToken: NSObjectProtocol?

        var actionsController: ConversationActionController?

        let shouldPresentNotificationPermissionHintUseCase: ShouldPresentNotificationPermissionHintUseCaseProtocol
        let didPresentNotificationPermissionHintUseCase: DidPresentNotificationPermissionHintUseCaseProtocol

        init(
            account: Account,
            selfUserLegalHoldSubject: SelfUserLegalHoldable,
            userSession: UserSession,
            isSelfUserE2EICertifiedUseCase: IsSelfUserE2EICertifiedUseCaseProtocol,
            notificationCenter: NotificationCenter = .default
        ) {
            self.account = account
            self.selfUserLegalHoldSubject = selfUserLegalHoldSubject
            self.userSession = userSession
            self.isSelfUserE2EICertifiedUseCase = isSelfUserE2EICertifiedUseCase
            selfUserStatus = .init(user: selfUserLegalHoldSubject, isE2EICertified: false)
            shouldPresentNotificationPermissionHintUseCase = ShouldPresentNotificationPermissionHintUseCase()
            didPresentNotificationPermissionHintUseCase = DidPresentNotificationPermissionHintUseCase()
            self.notificationCenter = notificationCenter
            super.init()

            updateE2EICertifiedStatus()
        }

        deinit {
            if let didBecomeActiveNotificationToken {
                notificationCenter.removeObserver(didBecomeActiveNotificationToken)
            }

            if let e2eiCertificateChangedToken {
                notificationCenter.removeObserver(e2eiCertificateChangedToken)
            }
        }
    }
}

extension ConversationListViewController.ViewModel {

    func setupObservers() {

        if let userSession = ZMUserSession.shared() {
            initialSyncObserverToken = NotificationInContext.addObserver(
                name: .initialSync,
                context: userSession.notificationContext
            ) { [weak self] _ in
                userSession.managedObjectContext.performGroupedBlock {
                    self?.requestMarketingConsentIfNeeded()
                }
            }

            userObservationToken = userSession.addUserObserver(self, for: selfUserLegalHoldSubject)
        }

        updateObserverTokensForActiveTeam()

        didBecomeActiveNotificationToken = notificationCenter.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateE2EICertifiedStatus()
        }

        e2eiCertificateChangedToken = notificationCenter.addObserver(
            forName: .e2eiCertificateChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateE2EICertifiedStatus()
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
        animated: Bool = false,
        completion: Completion? = nil
    ) {

        selectedConversation = conversation
        viewController?.selectOnListContentController(
            selectedConversation,
            scrollTo: message,
            focusOnView: focus,
            animated: animated,
            completion: completion
        )
    }

    func requestMarketingConsentIfNeeded() {
        if let userSession = ZMUserSession.shared(), let selfUser = ZMUser.selfUser() {
            guard
                userSession.hasCompletedInitialSync == true,
                userSession.isPendingHotFixChanges == false
            else {
                return
            }

            selfUser.fetchMarketingConsent(in: userSession) { [weak self] result in
                switch result {
                case .failure(let error):
                    switch error {
                    case ConsentRequestError.notAvailable:
                        // don't show the alert there is no consent to show
                        break
                    default:
                        self?.viewController?.showNewsletterSubscriptionDialogIfNeeded(completionHandler: { marketingConsent in
                            selfUser.setMarketingConsent(to: marketingConsent, in: userSession, completion: { _ in })
                        })
                    }
                case .success:
                    // The user already gave a marketing consent, no need to ask for it again.
                    return
                }
            }
        }
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

extension ConversationListViewController.ViewModel: UserObserving {

    func userDidChange(_ changeInfo: UserChangeInfo) {

        if changeInfo.nameChanged || changeInfo.imageMediumDataChanged || changeInfo.imageSmallProfileDataChanged || changeInfo.teamsChanged {
            viewController?.conversationListViewControllerViewModelRequiresUpdatingAccountView(self)
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
    }
}
