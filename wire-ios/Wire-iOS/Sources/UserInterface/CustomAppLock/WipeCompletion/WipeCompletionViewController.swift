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
import WireDesign

final class WipeCompletionViewController: UIViewController {
    // MARK: Lifecycle

    init() {
        super.init(nibName: nil, bundle: nil)

        view.backgroundColor = SemanticColors.View.backgroundDefault

        configureSubviews()
        createConstraints()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    let wireLogoInfoView = WireLogoInfoView(
        title: L10n.Localizable.WipeDatabaseCompletion.title,
        subtitle: L10n.Localizable.WipeDatabaseCompletion.subtitle
    )

    // MARK: Private

    private lazy var loginButton = {
        let button = ZMButton(style: .accentColorTextButtonStyle, cornerRadius: 16, fontSpec: .smallSemiboldFont)
        button.setTitle(L10n.Localizable.Signin.confirm, for: .normal)
        button.addTarget(self, action: #selector(onLoginCodeButtonPressed(sender:)), for: .touchUpInside)
        return button
    }()

    private func configureSubviews() {
        view.addSubview(wireLogoInfoView)

        wireLogoInfoView.contentView.addSubview(loginButton)
    }

    private func createConstraints() {
        [wireLogoInfoView, loginButton].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        NSLayoutConstraint.activate([
            wireLogoInfoView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            wireLogoInfoView.topAnchor.constraint(equalTo: view.topAnchor),
            wireLogoInfoView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            wireLogoInfoView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // log in button
            loginButton.heightAnchor.constraint(equalToConstant: CGFloat.WipeCompletion.buttonHeight),

            loginButton.bottomAnchor.constraint(equalTo: wireLogoInfoView.contentView.bottomAnchor, constant: -24),
            loginButton.leadingAnchor.constraint(equalTo: wireLogoInfoView.contentView.leadingAnchor),
            loginButton.trailingAnchor.constraint(equalTo: wireLogoInfoView.contentView.trailingAnchor),
        ])
    }

    @objc
    private func onLoginCodeButtonPressed(sender: AnyObject?) {
        dismiss(animated: true)
    }
}
