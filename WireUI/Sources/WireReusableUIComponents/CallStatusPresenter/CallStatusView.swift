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

import SwiftUI

final class CallStatusView: UIView {

    var callStatus: CallStatus? {
        didSet { updateStatusLabel() }
    }

    var topMargin: CGFloat {
        get { containerTopConstraint.constant }
        set { containerTopConstraint.constant = newValue }
    }

    private let statusLabel = UILabel()
    private var containerTopConstraint: NSLayoutConstraint!

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .green
        setupStatusLabel()
        updateStatusLabel()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    private func setupStatusLabel() {

        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        addSubview(container)

        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(statusLabel)

        let constraints = [

            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.topAnchor.constraint(equalTo: topAnchor), // topMargin constraint
            trailingAnchor.constraint(equalTo: container.trailingAnchor),
            bottomAnchor.constraint(equalTo: container.bottomAnchor),

            statusLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor), // lower priority
            statusLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor), // lower priority

            statusLabel.leadingAnchor.constraint(greaterThanOrEqualToSystemSpacingAfter: container.leadingAnchor, multiplier: 1),
            statusLabel.topAnchor.constraint(greaterThanOrEqualToSystemSpacingBelow: container.topAnchor, multiplier: 1),
            container.trailingAnchor.constraint(greaterThanOrEqualToSystemSpacingAfter: statusLabel.trailingAnchor, multiplier: 1),
            container.bottomAnchor.constraint(greaterThanOrEqualToSystemSpacingBelow: statusLabel.bottomAnchor, multiplier: 1),
        ]
        containerTopConstraint = constraints[1]
        constraints[4...5].forEach { constraint in constraint.priority = .defaultHigh }
        NSLayoutConstraint.activate(constraints)
    }

    private func updateStatusLabel() {
        statusLabel.text = callStatus
    }
}

// MARK: - Previews

@available(iOS 17, *)
#Preview {
    {
        let callStatusView = CallStatusView()
        callStatusView.callStatus = "Connecting ..."
        return callStatusView
    }()
}
