//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

import Foundation
import UIKit

final class ContactsSectionHeaderView: UITableViewHeaderFooterView {
    let label: UILabel = {
        let label = UILabel()
        label.font = .smallSemiboldFont
        label.textColor = .from(scheme: .textForeground, variant: .dark)

        return label
    }()
    static let height: CGFloat = 20
    var sectionTitleLeftConstraint: NSLayoutConstraint!

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        let blurEffect = UIBlurEffect(style: .light)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = bounds
        blurEffectView.backgroundColor = .clear

        backgroundView = blurEffectView

        setupSubviews()
        setupConstraints()
        setupStyle()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubviews() {
        contentView.addSubview(label)
    }

    func setupStyle() {
        self.textLabel?.isHidden = true
    }

    private func setupConstraints() {

        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
          label.centerYAnchor.constraint(equalTo: centerYAnchor),
          label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24)
        ])
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: ContactsSectionHeaderView.height)
    }

}
