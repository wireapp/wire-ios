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

final class TopBar: UIView {

    var leftView: UIView? = .none {
        didSet {
            oldValue?.removeFromSuperview()

            guard let new = leftView else {
                return
            }

            addSubview(new)

            new.translatesAutoresizingMaskIntoConstraints = false

            var constraints = [
                new.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
                new.centerYAnchor.constraint(equalTo: centerYAnchor)]

            if let middleView {
                constraints.append(new.trailingAnchor.constraint(lessThanOrEqualTo: middleView.leadingAnchor))
            }

            NSLayoutConstraint.activate(constraints)
        }
    }

    var rightView: UIView? = .none {
        didSet {
            oldValue?.removeFromSuperview()

            guard let new = rightView else {
                return
            }

            addSubview(new)

            new.translatesAutoresizingMaskIntoConstraints = false

            var constraints = [
                new.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
                new.centerYAnchor.constraint(equalTo: centerYAnchor)]

            if let middleView {
                constraints.append(new.leadingAnchor.constraint(greaterThanOrEqualTo: middleView.trailingAnchor))
            }

            NSLayoutConstraint.activate(constraints)
        }

    }

    private let middleViewContainer = UIView()

    var middleView: UIView? = .none {
        didSet {
            oldValue?.removeFromSuperview()

            guard let new = middleView else {
                return
            }

            middleViewContainer.addSubview(new)

            new.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                new.centerYAnchor.constraint(equalTo: middleViewContainer.centerYAnchor),
                new.centerXAnchor.constraint(equalTo: middleViewContainer.centerXAnchor),

                new.widthAnchor.constraint(equalTo: middleViewContainer.widthAnchor),
                new.heightAnchor.constraint(equalTo: middleViewContainer.heightAnchor)])
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        layoutMargins = UIEdgeInsets(top: 0, left: CGFloat.ConversationList.horizontalMargin, bottom: 0, right: CGFloat.ConversationList.horizontalMargin)

        middleViewContainer.translatesAutoresizingMaskIntoConstraints = false
        addSubview(middleViewContainer)

        NSLayoutConstraint.activate([
            middleViewContainer.centerXAnchor.constraint(equalTo: centerXAnchor),
            middleViewContainer.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override var intrinsicContentSize: CGSize {
        .init(
            width: UIView.noIntrinsicMetric,
            height: CGFloat.ConversationListHeader.barHeight
        )
    }
}
