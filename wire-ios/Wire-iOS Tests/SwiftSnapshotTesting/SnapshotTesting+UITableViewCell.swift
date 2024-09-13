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

extension UITableViewCell: UITableViewDelegate, UITableViewDataSource {
    func wrapInTableView() -> UITableView {
        let tableView = UITableView(frame: bounds, style: .plain)

        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.layoutMargins = layoutMargins

        let size = systemLayoutSizeFitting(
            CGSize(width: bounds.width, height: 0.0),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        layoutSubviews()

        bounds = CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height)
        contentView.bounds = bounds

        tableView.reloadData()
        tableView.bounds = bounds
        tableView.layoutIfNeeded()

        NSLayoutConstraint.activate([
            tableView.heightAnchor.constraint(equalToConstant: size.height),
        ])

        layoutSubviews()
        return tableView
    }

    public func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        bounds.size.height
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        self
    }
}
