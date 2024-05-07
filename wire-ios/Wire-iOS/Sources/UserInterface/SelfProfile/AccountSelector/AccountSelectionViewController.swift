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
import WireSyncEngine
import WireSystem

final class AccountSelectionViewController: UIViewController {

    private let accountSwitcher: AccountSwitcher
    private var accountsView = AccountSelectorView()
    private var applicationDidBecomeActiveToken: NSObjectProtocol!

    init(accountSwitcher: AccountSwitcher) {
        self.accountSwitcher = accountSwitcher
        super.init(nibName: nil, bundle: nil)

        applicationDidBecomeActiveToken = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            self?.updateShowAccountsIfNeeded()
        }

        accountsView.delegate = self
        view.addSubview(accountsView)
        accountsView.translatesAutoresizingMaskIntoConstraints = false
        accountsView.fitIn(view: view)
        accountsView.accounts = SessionManager.shared?.accountManager.accounts ?? []

        setShowAccounts(to: SessionManager.shared?.accountManager.accounts.count > 1)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var showAccounts: Bool = false

    func updateShowAccountsIfNeeded() {
        let showAccounts = SessionManager.shared?.accountManager.accounts.count > 1
        guard showAccounts != showAccounts else { return }
        setShowAccounts(to: showAccounts)
    }

    private func setShowAccounts(to showAccounts: Bool) {
        self.showAccounts = showAccounts
        accountsView.isHidden = !showAccounts
        view.frame.size = accountsView.frame.size
    }
}

extension AccountSelectionViewController: AccountSelectorViewDelegate {

    func accountSelectorDidSelect(account: Account) {
        guard
            account != accountSwitcher.currentAccount,
            ZClientViewController.shared?.conversationListViewController.presentedViewController != nil
        else { return }

        ZClientViewController.shared?.conversationListViewController.dismiss(animated: true) {

            AppDelegate.shared.mediaPlaybackManager?.stop()
            Task {
                do {
                    try await self.accountSwitcher.switchTo(account: account)
                } catch {
                    WireLogger.sessionManager.error("failed to switch accounts: \(error)")
                }
            }
        }
    }
}
