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

// MARK: - AccountSelectorViewDelegate

protocol AccountSelectorViewDelegate: AnyObject {
    func accountSelectorView(_ view: AccountSelectorView, didSelect account: Account)
}

// MARK: - AccountSelectorView

final class AccountSelectorView: UIView {
    // MARK: Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    // MARK: Internal

    weak var delegate: AccountSelectorViewDelegate?

    var accounts = [Account]() {
        didSet { updateStackView() }
    }

    // MARK: Private

    private let stackView = UIStackView()

    private func setupSubviews() {
        stackView.spacing = 6
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.heightAnchor.constraint(equalTo: heightAnchor),
        ])
    }

    private func updateStackView() {
        for subview in stackView.arrangedSubviews {
            subview.removeFromSuperview()
        }
        for account in accounts {
            let accountView = AccountViewBuilder(account: account, displayContext: .accountSelector).build()
            accountView.unreadCountStyle = .current
            accountView.onTap = { [weak self] account in
                self?.delegate?.accountSelectorView(self!, didSelect: account)
            }
            stackView.addArrangedSubview(accountView)
        }
    }
}
