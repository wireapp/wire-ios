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

// TODO [WPB-7307]: remove typealias
typealias AccountSelectorController = AccountSelectionViewController

final class AccountSelectionViewController: UIViewController {

    weak var delegate: AccountSelectionViewControllerDelegate?

    private var accountsView = AccountSelectorView()
    private var applicationDidBecomeActiveToken: NSObjectProtocol!

    init() {
        super.init(nibName: nil, bundle: nil)

        applicationDidBecomeActiveToken = NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: nil, using: { [weak self] _ in
            self?.updateShowAccountsIfNeeded()
        })

        accountsView.delegate = self
        view.addSubview(accountsView)
        accountsView.translatesAutoresizingMaskIntoConstraints = false
        accountsView.fitIn(view: view)

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

extension AccountSelectorController: AccountSelectorViewDelegate {

    func accountSelectorDidSelect(account: Account) {
        guard
            account != SessionManager.shared?.accountManager.selectedAccount,
            ZClientViewController.shared?.conversationListViewController.presentedViewController != nil
        else { return }

        ZClientViewController.shared?.conversationListViewController.dismiss(animated: true) {

            AppDelegate.shared.mediaPlaybackManager?.stop()
            self.delegate?.accountSelectionViewController(self, didSwitchTo: account)
        }
    }
}
