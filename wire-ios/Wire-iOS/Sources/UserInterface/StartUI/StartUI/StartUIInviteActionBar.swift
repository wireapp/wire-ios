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

final class StartUIInviteActionBar: UIView {
    // MARK: Lifecycle

    init() {
        super.init(frame: .zero)
        backgroundColor = SemanticColors.View.backgroundUserCell

        createInviteButton()
        createConstraints()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardFrameWillChange(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    var bottomEdgeConstraint: NSLayoutConstraint!

    private(set) var inviteButton: ZMButton!

    override var isHidden: Bool {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: isHidden ? 0 : 56.0)
    }

    // MARK: Private

    private let padding: CGFloat = 12

    private func createInviteButton() {
        inviteButton = .init(
            style: .accentColorTextButtonStyle,
            cornerRadius: 16,
            fontSpec: .normalSemiboldFont
        )
        inviteButton.titleEdgeInsets = UIEdgeInsets(top: 2, left: 8, bottom: 3, right: 8)
        inviteButton.setTitle(L10n.Localizable.Peoplepicker.inviteMorePeople.capitalized, for: .normal)
        addSubview(inviteButton)
    }

    private func createConstraints() {
        inviteButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            inviteButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding * 2),
            inviteButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -(padding * 2)),
            inviteButton.bottomAnchor.constraint(
                equalTo: bottomAnchor,
                constant: -(padding + UIScreen.safeArea.bottom)
            ),
            inviteButton.topAnchor.constraint(equalTo: topAnchor, constant: padding),
        ])
        bottomEdgeConstraint = inviteButton.bottomAnchor.constraint(
            equalTo: bottomAnchor,
            constant: -(padding + UIScreen.safeArea.bottom)
        )
        bottomEdgeConstraint.isActive = true

        inviteButton.heightAnchor.constraint(equalToConstant: 56).isActive = true
    }

    // MARK: - UIKeyboard notifications

    @objc
    private func keyboardFrameWillChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let beginOrigin = (userInfo[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue.origin.y,
              let endOrigin = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.origin.y
        else {
            return
        }

        let diff: CGFloat = beginOrigin - endOrigin

        UIView.animate(withKeyboardNotification: notification, in: self, animations: { [weak self] _ in
            guard let self else {
                return
            }

            bottomEdgeConstraint.constant = -padding - (diff > 0 ? 0 : UIScreen.safeArea.bottom)
            layoutIfNeeded()
        })
    }
}
