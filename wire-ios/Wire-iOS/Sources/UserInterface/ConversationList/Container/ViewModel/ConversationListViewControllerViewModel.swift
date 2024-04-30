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

    func setState(
        _ state: ConversationListState,
        animated: Bool,
        completion: Completion?
    )

    func showNoContactLabel(animated: Bool)
    func hideNoContactLabel(animated: Bool)
    func showNewsletterSubscriptionDialogIfNeeded(completionHandler: @escaping ResultHandler)
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
        let selfUser: SelfUserType
        let conversationListType: ConversationListHelperType.Type
        let userSession: UserSession
        private let notificationCenter: NotificationCenter

        var selectedConversation: ZMConversation?

        private var didBecomeActiveNotificationToken: NSObjectProtocol?
        private var e2eiCertificateChangedToken: NSObjectProtocol?
        private var initialSyncObserverToken: Any?
        /// observer tokens which are assigned when viewDidLoad
        var allConversationsObserverToken: NSObjectProtocol?
        var connectionRequestsObserverToken: NSObjectProtocol?

        var actionsController: ConversationActionController?

        init(
            account: Account,
            selfUser: SelfUserType,
            conversationListType: ConversationListHelperType.Type = ZMConversationList.self,
            userSession: UserSession,
            notificationCenter: NotificationCenter = .default
        ) {
            self.account = account
            self.selfUser = selfUser
            self.conversationListType = conversationListType
            self.userSession = userSession
            self.notificationCenter = notificationCenter
            super.init()
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
            initialSyncObserverToken = ZMUserSession.addInitialSyncCompletionObserver(self, userSession: userSession)
        }

        updateObserverTokensForActiveTeam()
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
    func select(conversation: ZMConversation,
                scrollTo message: ZMConversationMessage? = nil,
                focusOnView focus: Bool = false,
                animated: Bool = false,
                completion: Completion? = nil) {
        selectedConversation = conversation

        viewController?.setState(.conversationList, animated: animated) { [weak self] in
            self?.viewController?.selectOnListContentController(self?.selectedConversation, scrollTo: message, focusOnView: focus, animated: animated, completion: completion)
        }
    }

    func requestMarketingConsentIfNeeded() {
        if let userSession = ZMUserSession.shared(), let selfUser = ZMUser.selfUser() {
            guard
                userSession.hasCompletedInitialSync == true,
                userSession.isPendingHotFixChanges == false
            else {
                return
            }

            selfUser.fetchMarketingConsent(in: userSession, completion: {[weak self] result in
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
            })
        }
    }

    private var isComingFromRegistration: Bool {
        return ZClientViewController.shared?.isComingFromRegistration ?? false
    }

    /// show PushPermissionDeniedDialog when necessary
    ///
    /// - Returns: true if PushPermissionDeniedDialog is shown

    @discardableResult
    func showPushPermissionDeniedDialogIfNeeded() -> Bool {
        // We only want to present the notification takeover when the user already has a handle
        // and is not coming from the registration flow (where we alreday ask for permissions).
        guard selfUser.handle != nil else { return false }
        guard !isComingFromRegistration else { return false }
        guard !AutomationHelper.sharedHelper.skipFirstLoginAlerts else { return false }

        guard Settings.shared.pushAlertHappenedMoreThan1DayBefore else { return false }

        UNUserNotificationCenter.current().checkPushesDisabled { [weak self] pushesDisabled in
            DispatchQueue.main.async {
                if pushesDisabled, let self {
                    Settings.shared[.lastPushAlertDate] = Date()
                    self.viewController?.showPermissionDeniedViewController()
                }
            }
        }

        return true
    }
}

extension ConversationListViewController.ViewModel: ZMInitialSyncCompletionObserver {

    func initialSyncCompleted() {
        requestMarketingConsentIfNeeded()
    }
}

extension Settings {
    var pushAlertHappenedMoreThan1DayBefore: Bool {
        guard let date: Date = self[.lastPushAlertDate] else {
            return true
        }

        return date.timeIntervalSinceNow < -86400
    }
}
