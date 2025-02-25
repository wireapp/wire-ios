//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

final class ConversationStackMessageContentView: UIView, ConversationMessageContentView {

//    private let stackView = {
//        let stackView = UIStackView()
//        stackView.axis = .vertical
//        return stackView
//    }()
    private var stackView = UIStackView() {
        didSet {
            oldValue.removeFromSuperview()
            setupStackView()
        }
    }

    var isSelected = false

    var message: (any ZMConversationMessage)?

    var delegate: (any ConversationMessageCellDelegate)?

    func configure(with configuration: [AnyConversationMessageCellDescription], animated: Bool) {
        let arrangedSubviews = configuration.map { cellDescription in
            // cellDescription.makeView() // TODO: call C.View(...)
            fatalError()
            return UIView()
        }
        stackView = .init(arrangedSubviews: arrangedSubviews)
    }

    private func setupStackView() {
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
            bottomAnchor.constraint(equalTo: stackView.bottomAnchor)
        ])
    }

}
