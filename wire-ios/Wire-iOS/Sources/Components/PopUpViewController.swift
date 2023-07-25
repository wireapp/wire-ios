//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

class PopUpViewController: UIViewController {
    private let titleText: String
    private let messageText: String

    required init(title: String, message: String) {
        self.titleText = title
        self.messageText = message
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        super.loadView()
        setupViews()
    }

}

private extension PopUpViewController {

    func setupViews() {
        view.backgroundColor = .gray.withAlphaComponent(0.3)
        let containerView = UIView()
        containerView.backgroundColor = SemanticColors.View.backgroundDefault
        containerView.layer.masksToBounds = true
        containerView.layer.cornerRadius = 10.0
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)



        let stackView = UIStackView(axis: .vertical)
        stackView.spacing = 24.0
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)

        let titleLabel = DynamicFontLabel(fontSpec: .normalSemiboldFont, color: SemanticColors.Label.textDefault)
        titleLabel.numberOfLines = 0
        titleLabel.text = titleText
        stackView.addArrangedSubview(titleLabel)

        let messageLabel = DynamicFontLabel(fontSpec: .normalRegularFont, color: SemanticColors.Label.textDefault)
        messageLabel.numberOfLines = 0
        messageLabel.text = messageText
        stackView.addArrangedSubview(messageLabel)

        let okButton = Button(style: .accentColorTextButtonStyle,
                                        cornerRadius: 16,
                                        fontSpec: .normalSemiboldFont)
        okButton.setTitle(L10n.Localizable.General.confirm, for: .normal)
        okButton.addTarget(self, action: #selector(okAction), for: .touchUpInside)
        stackView.addArrangedSubview(okButton)

        stackView.fitIn(view: containerView, inset: 32.0)
        NSLayoutConstraint.activate([
            okButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 46.0),
            okButton.widthAnchor.constraint(equalTo: stackView.widthAnchor),
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.7)
        ])
    }

    @objc func okAction() {
        dismiss(animated: true, completion: nil)
    }
}
