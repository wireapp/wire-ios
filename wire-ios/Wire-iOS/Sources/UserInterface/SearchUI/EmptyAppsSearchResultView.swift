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
import WireDesign

final class EmptyAppsSearchResultView: UIView {

    private let canManageTeam: Bool

    required init(canManageTeam: Bool) {
        self.canManageTeam = canManageTeam
        super.init()
        setup()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    private func setup() {
        let headlineLabel = UILabel()
        headlineLabel.numberOfLines = 0
        headlineLabel.text = L10n.Localizable.Peoplepicker.NoAppsAdded.title
        headlineLabel.font = .font(for: .body1).withWeight(.bold)
        let contentLabel = UILabel()
        contentLabel.numberOfLines = 0
        contentLabel.text = canManageTeam
        ? L10n.Localizable.Peoplepicker.NoAppsAdded.addInTmMessage
        : L10n.Localizable.Peoplepicker.NoAppsAdded.askAdminMessage
        contentLabel.font = .font(for: .body1)
        let stackView = UIStackView(arrangedSubviews: [headlineLabel, contentLabel])
        stackView.axis = .vertical
        stackView.spacing = 24
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            trailingAnchor.constraint(greaterThanOrEqualTo: stackView.trailingAnchor, constant: 16),
            bottomAnchor.constraint(greaterThanOrEqualTo: stackView.bottomAnchor, constant: 16)
        ])
    }

}

@available(iOS 17, *)
#Preview("Admin") {
    EmptyAppsSearchResultView(canManageTeam: true)
}

@available(iOS 17, *)
#Preview("Non-admin") {
    EmptyAppsSearchResultView(canManageTeam: false)
}
