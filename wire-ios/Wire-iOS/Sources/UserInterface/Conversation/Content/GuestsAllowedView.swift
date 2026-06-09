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
import WireDesign
import WireUtilities

final class GuestsAllowedView: UIView {

    var onInviteTapped: (() -> Void)?

    private let stackView = UIStackView()
    private let titleLabel = UILabel()
    let inviteButton = SecondaryTextButton()
    private let wireDriveViewerAccessLabel = UILabel()

    init(isChannel: Bool, isWireDriveEnabled: Bool) {
        super.init(frame: .zero)
        setupViews(isChannel: isChannel, isWireDriveEnabled: isWireDriveEnabled)
        createConstraints()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) { fatalError() }

    private func setupViews(isChannel: Bool, isWireDriveEnabled: Bool) {
        typealias System = L10n.Localizable.Content.System
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.alignment = .leading
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        // TODO: [WPB-25941] Remove developer flag when feature is complete
        [
            titleLabel,
            inviteButton,
            isWireDriveEnabled && DeveloperFlag.enableDrivePermissions.isOn ? wireDriveViewerAccessLabel : nil
        ]
        .compactMap(\.self)
        .forEach(stackView.addArrangedSubview)

        titleLabel.numberOfLines = 0
        titleLabel.textColor = SemanticColors.Label.textDefault
        titleLabel.font = FontSpec.mediumFont.font!
        titleLabel.text = isChannel ? System.Channel.Invite.title : System.Conversation.Invite.title

        let buttonTitle = isChannel ? System.Channel.Invite.button : System.Conversation.Invite.button
        inviteButton.setTitle(buttonTitle, for: .normal)
        inviteButton.addTarget(self, action: #selector(handleInviteTapped), for: .touchUpInside)

        // TODO: [WPB-25941] Remove developer flag when feature is complete
        if isWireDriveEnabled, DeveloperFlag.enableDrivePermissions.isOn {
            wireDriveViewerAccessLabel.text = System.FileCollaboration.DriveViewerAccess.title
            wireDriveViewerAccessLabel.numberOfLines = 0
            wireDriveViewerAccessLabel.textColor = ColorTheme.Backgrounds.onSurface
            wireDriveViewerAccessLabel.font = FontSpec.mediumFont.font!
        }
    }

    private func createConstraints() {
        let inset = GroupConversationHeaderView.textInset
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: inset),
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            trailingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: inset),
            bottomAnchor.constraint(equalTo: stackView.bottomAnchor)
        ])
    }

    @objc
    private func handleInviteTapped() {
        onInviteTapped?()
    }
}
