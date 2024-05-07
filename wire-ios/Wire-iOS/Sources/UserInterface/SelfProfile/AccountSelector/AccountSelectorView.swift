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
import WireDataModel
import WireSyncEngine

protocol AccountSelectorViewDelegate: AnyObject {
    func accountSelectorDidSelect(account: Account)
}

final class AccountSelectorView: UIView {

    weak var delegate: AccountSelectorViewDelegate?

    private var accountViews: [BaseAccountView] = []
    private let lineView = UIStackView()

    var accounts = [Account]() {
        didSet {
            lineView.arrangedSubviews.forEach { subview in
                subview.removeFromSuperview()
            }
            accountViews = accounts.compactMap { account in
                AccountViewFactory.viewFor(account: account, displayContext: .accountSelector)
            }
            accountViews.forEach { accountView in
                accountView.unreadCountStyle = .current
                accountView.onTap = { [weak self] account in
                    self?.delegate?.accountSelectorDidSelect(account: account)
                }
                lineView.addArrangedSubview(accountView)
                accountView.collapsed = false
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    private func setupSubviews() {
        lineView.spacing = 6
        lineView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(lineView)
        NSLayoutConstraint.activate([
            lineView.centerYAnchor.constraint(equalTo: centerYAnchor),
            lineView.leadingAnchor.constraint(equalTo: leadingAnchor),
            lineView.trailingAnchor.constraint(equalTo: trailingAnchor),
            lineView.heightAnchor.constraint(equalTo: heightAnchor)
        ])
    }
}
