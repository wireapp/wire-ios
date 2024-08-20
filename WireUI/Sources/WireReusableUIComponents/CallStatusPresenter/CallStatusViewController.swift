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

final class CallStatusViewController: UIViewController {

    var callStatus: CallStatus? {
        didSet { updateStatusLabel() }
    }

    private let statusLabel = UILabel()

    init(callStatus: CallStatus?) {
        self.callStatus = callStatus
        super.init(nibName: nil, bundle: nil)
        updateStatusLabel()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .green
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusLabel)
        let statusBarHeight = view.window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
        let constraints = [
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            statusLabel.leadingAnchor.constraint(greaterThanOrEqualToSystemSpacingAfter: view.leadingAnchor, multiplier: 1),
            statusLabel.topAnchor.constraint(greaterThanOrEqualTo: view.topAnchor, constant: statusBarHeight),
            view.trailingAnchor.constraint(greaterThanOrEqualToSystemSpacingAfter: statusLabel.trailingAnchor, multiplier: 1),
            view.bottomAnchor.constraint(greaterThanOrEqualToSystemSpacingBelow: statusLabel.bottomAnchor, multiplier: 1),
        ]
        constraints[0...1].forEach { constraint in constraint.priority = .defaultHigh }
        NSLayoutConstraint.activate(constraints)
    }

    private func updateStatusLabel() {
        statusLabel.text = callStatus
    }
}

// MARK: - Previews

@available(iOS 17, *)
#Preview {
    CallStatusViewController(callStatus: "Connecting ...")
}
