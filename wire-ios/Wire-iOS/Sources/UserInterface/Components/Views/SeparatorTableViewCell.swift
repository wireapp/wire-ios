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

class SeparatorTableViewCell: UITableViewCell, SeparatorViewProtocol {
    // MARK: Lifecycle

    // MARK: - Initialization

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureSubviews()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init?(coder aDecoder: NSCoder) is not implemented")
    }

    // MARK: Internal

    typealias CellColors = SemanticColors.View

    let separator = UIView()
    var separatorInsetConstraint: NSLayoutConstraint!

    var separatorLeadingAnchor: NSLayoutXAxisAnchor {
        contentView.layoutMarginsGuide.leadingAnchor
    }

    var separatorLeadingInset: CGFloat = 0 {
        didSet {
            separatorInsetConstraint?.constant = separatorLeadingInset
        }
    }

    var showSeparator: Bool {
        get { !separator.isHidden }
        set { separator.isHidden = !newValue }
    }

    override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted
                ? CellColors.backgroundUserCellHightLighted
                : CellColors.backgroundUserCell
        }
    }

    func setUp() {
        // can be overriden to customize interface
    }

    // MARK: Private

    private func configureSubviews() {
        setUp()

        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.backgroundColor = CellColors.backgroundSeparatorCell
        backgroundColor = CellColors.backgroundUserCell

        contentView.addSubview(separator)

        createSeparatorConstraints()
    }
}
