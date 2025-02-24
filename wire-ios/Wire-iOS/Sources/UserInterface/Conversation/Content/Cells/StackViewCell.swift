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

import SwiftUI
import WireFoundation
import WireDesign
import WireDataModel

final class StackViewCell: UITableViewCell {

    let stackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        return stackView
    }()

    private lazy var longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(onLongPress))
    private lazy var doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(onDoubleTap))
    private lazy var singleTapGesture = UITapGestureRecognizer(target: self, action: #selector(onSingleTap))

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    private func setup() {

        focusStyle = .custom
        selectionStyle = .none
        backgroundColor = .clear
        isOpaque = false

        contentView.addGestureRecognizer(longPressGesture)

        doubleTapGesture.numberOfTapsRequired = 2
        contentView.addGestureRecognizer(doubleTapGesture)

        let tempCellView = self
        tempCellView.addGestureRecognizer(singleTapGesture)
        singleTapGesture.require(toFail: doubleTapGesture)
        singleTapGesture.delegate = self

        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
            bottomAnchor.constraint(equalTo: stackView.bottomAnchor)
        ])
    }

    @objc
    private func onLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            //showMenu()
            fatalError("TODO")
        }
    }

    @objc
    private func onDoubleTap(_ gestureRecognizer: UITapGestureRecognizer) {
        fatalError("TODO")
//        if gestureRecognizer.state == .recognized, cellDescription?.supportsActions == true {
//            cellDescription?.actionController?.performDoubleTapAction()
//        }
    }

    @objc
    private func onSingleTap(_ gestureRecognizer: UITapGestureRecognizer) {
        fatalError("TODO")
//        if gestureRecognizer.state == .recognized, cellDescription?.supportsActions == true {
//            cellDescription?.actionController?.performSingleTapAction()
//        }
    }

}
