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
import WireCommonComponents
import WireDataModel
import WireDesign

final class WarningLabelView: UIView {
    private let stackView = UIStackView(axis: .vertical)

    private let label = DynamicFontLabel(
        style: .h5,
        color: SemanticColors.Label.textErrorDefault
    )

    private static let paragraphStyle: NSParagraphStyle = {
        let style = NSMutableParagraphStyle()
        style.paragraphSpacing = 8
        style.alignment = .center
        return style
    }()

    // MARK: - Setup

    init() {
        super.init(frame: .zero)
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        stackView.alignment = .center
        stackView.spacing = 10
        label.numberOfLines = 0
        stackView.addArrangedSubview(label)
        NSLayoutConstraint.activate(
            NSLayoutConstraint.forView(
                    view: stackView,
                    inContainer: self,
                    withInsets: .zero
                )
        )
    }

    func update(withUser user: UserType) {
        typealias profileDetails = L10n.Localizable.Profile.Details
        if user.isPendingApprovalBySelfUser {
            isHidden = false
            label.attributedText = attributedWarning(profileDetails.requestedIdentityWarning)
        }
        guard let name = user.name else {
            isHidden = true
            return
        }
        isHidden = user.isConnected || user.isTeamMember || user.isSelfUser
        label.attributedText = attributedWarning(profileDetails.identityWarning(name))
    }

    private func attributedWarning(_ text: String) -> NSAttributedString {
        NSAttributedString(string: text, attributes: [.paragraphStyle: Self.paragraphStyle])
    }
}
